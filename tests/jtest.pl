use strict;

use Getopt::Long;

use WebGear::HTML::Constants;
use WebGear::HTML::DOM;
use WebGear::SpiderMonkey;

#===============================================================================
#       Тестирование JSDOM
#
# Имена файлов и каталогов начинающиеся с символа '_' и файлы с раширением
# отличным от '.dat' пропускаются, вложенные подкаталоги не обрабатываются.
#===============================================================================

my ( 
    @names, $excludenames, $regexp, $force, $split, 
    $D, $SD, $IF, $OF, $directoryname, $subdirectoryname, $inputfilename, 
    @entry, $text,
    $document, $jsruntime, $jscontext
);

$regexp = "^.*\$";

GetOptions(
    'n=s{,}' => \@names,        # Список подкаталогов.
    'x'      => \$excludenames, # Указанные имена будут пропущены.
    'r=s'    => \$regexp,       # Регулярное выражение имен подкаталогов.
    'f'      => \$force,        # Продолжить выполнение при ошибке.
    's'      => \$split         # Дополнительные файлы для сравнения.
);
           
$regexp = "^(" . join("|", @names) . ")\$" if @names;

$directoryname = "js";

opendir $D, $directoryname || die $!;

printf "%s\n%30s %s     %s\n\n", "SUBDIR", "FILE", "LINE", "RESULT";
       
$jsruntime = js_initialize_runtime();
    
foreach $subdirectoryname (readdir $D) { 
    # Пропуск имен каталогов начинающихся с '_' и '.'.
    next unless -d "$directoryname/$subdirectoryname" && $subdirectoryname !~ /^(\.|_)/;

    if ($subdirectoryname =~ /$regexp/) {
        next if $excludenames;
    } else {
        next unless $excludenames;
    }

    opendir $SD, "$directoryname/$subdirectoryname" || die $!;
    
    print "$subdirectoryname\n";

    foreach $inputfilename (readdir $SD) {   
        # пропуск имен файлов начинающихся с '_'
        next unless -f "$directoryname/$subdirectoryname/$inputfilename" && $inputfilename =~ /^[^_].*\.dat$/;
        # Сброс $.
        close $IF if $IF;
        open  $IF, "<$directoryname/$subdirectoryname/$inputfilename" || die $!;

        while (<$IF>) {

            if (/^\s*#data,?\s*(.*)/) {
                # [0] - параметры.
                # [1] - номер строки #data + 1.
                # [2] - данные.
                # [3] - ожидаемый результат.
                @entry = ();
            
                $entry[0] = $1;
                $entry[1] = $. + 1; # номер следующей строки.

                while (<$IF>) { # #data
                    last if /^\s*#document/;
                    $entry[2] .= $_;
                }

                while (<$IF>) { # #document
                    last if /^\s*(@|$)/;
                    last if /^#/;
                    $entry[3] .= $_;
                }
                
                # Удаляем завершающий символ новой строки вне зависимости от платформы.
                $entry[2] =~ s/\R$//;
                $entry[3] =~ s/\R$//;
                # Приводим все символы новой строки к одному виду.
                # $entry[2] =~ s/\R/\n/g;
                # $entry[3] =~ s/\R/\n/g;

                #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  
                $text = "";
                
                $document  = node_create_document(); 
                $jscontext = js_initialize_context($jsruntime, {}, $document);
                
                js_evaluate($jscontext, $entry[2], length $entry[2]);
                
                js_destroy_context($jscontext);
    
                $text =~ s/\R$//;              
                #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                
                if ($entry[3] ne $text) {
                    open   $OF, ">$directoryname/$subdirectoryname/error($inputfilename.[$entry[1]]).txt" || die $!;

                    printf $OF "-%d-\n\n", $entry[1];
                    printf $OF "#%s\n",    $entry[0] if $entry[0];
                    printf $OF "%s\n===>\n%s\n===>\n" .
                                "\t!=\n"              .
                                "<===\n%s\n<===",
                                $entry[2], $entry[3], $text;
                                
                    if ($split) {
                        open   $OF, ">$directoryname/$subdirectoryname/error($inputfilename.[$entry[1]]).a.txt" || die $!;
                        printf $OF "%s\n", $entry[3];

                        open   $OF, ">$directoryname/$subdirectoryname/error($inputfilename.[$entry[1]]).b.txt" || die $!;
                        printf $OF "%s\n", $text;
                    }             
                                
                    $text = "ERROR";
                } else {
                    $text = "OK";
                }

                printf "%30s %5s => %s\n", $inputfilename, $entry[1], $text;

                die if !$force && $text ne "OK";
            }
        }
    }
}

js_destroy_runtime($jsruntime);

printf("--END--\n");

sub js_callback 
{
    my ($name) = shift;
    my ($message, $node, $space, $depth, $event);

    if ($name eq "js_console_log") {
        $message  = $_[0];
        $text    .= sprintf "%s\n", $message;
    } elsif ($name eq "js_console_tree") {
        $node = $_[0];
        
        while (1) {

            if ($node->{'type'} == $NODE_TYPE_ELEMENT) {    
                $text .= sprintf "%s%s", 
                                 $space, $node->{'id'} ? element_id_to_name($node->{'id'}) :
                                 $node->{'name'};
                                                       
                foreach (sort keys %{$node->{'attributes'}}) {
                    $text .= sprintf ", %s", 
                                     $node->{'attributes'}{$_}{'name'};
                    $text .= sprintf "='%s'", 
                                     $node->{'attributes'}{$_}{'value'} if 
                                     $node->{'attributes'}{$_}{'valuelength'}; 
                }               
           
                foreach (sort keys %{$node->{'events'}}) {
                    $event = $node->{'events'}{$_};
                
                    while ($event) {
                        $text .= sprintf ", 'on%s':%d", 
                                         $event->{'type'},
                                         $event->{'flags'};
                        $event = $event->{'nextnode'};
                    }
                }  
                
                $text .= sprintf "\n";                    
            } elsif ($node->{'type'} == $NODE_TYPE_TEXT) {
                $text .= sprintf "%s\"%s\"\n", 
                                 $space, $node->{'data'};            
            } elsif ($node->{'type'} == $NODE_TYPE_COMMENT) {
                $text .= sprintf "%s!%s!\n", 
                                 $space, $node->{'data'};
            }  

            if ($node->{'firstchild'}) {
                $node = $node->{'firstchild'};
                $space = ' ' x (++$depth * 2);
                next;
            }
        L:    
            if ($node->{'nextsibling'}) {
                $node = $node->{'nextsibling'};
                next;
            }
            
            if (!$depth) {
                last;
            }

            $space = ' ' x (--$depth * 2);
            
            if ($node = $node->{'parent'}) {
                goto L;
            }
        }
    }
}
