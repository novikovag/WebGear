#===============================================================================
#      Тестирование парсера
#
# Имена файлов и каталогов начинающиеся с символа '_' и файлы с раширением
# отличным от '.dat' пропускаются, вложенные подкаталоги не обрабатываются.
#===============================================================================

use strict;

use Getopt::Long;

use WebGear::HTML::Filter;
use WebGear::HTML::Constants;
use WebGear::HTML::DOM;
use WebGear::HTML::Tries;
use WebGear::HTML::Parser;

my (
    @names, $excludenames, $regexp, $force, $split,
    $D, $SD, $IF, $OF, $directoryname, $subdirectoryname, $inputfilename, 
    @entry, @data, 
    $inbuffer,  $context, $document, $elementname, $element, $text
);

$regexp = "^.*\$";

GetOptions(
    'n=s{,}' => \@names,        # Список подкаталогов.
    'x'      => \$excludenames, # Указанные имена будут пропущены.
    'r=s'    => \$regexp,       # Регулярное выражение имен подкаталогов.
    'f'      => \$force,        # Продолжить выполнение при ошибке.
    's'      => \$split         # Дополнительные файлы для сравнения.
);
           
$regexp = "^(" . join("|", @names). ")\$" if @names;

$directoryname = "parser";

opendir $D, $directoryname || die $!;

printf "%s\n%30s %s     %s\n\n", "SUBDIR", "FILE", "LINE", "RESULT";
       
foreach $subdirectoryname (readdir $D) { 
    # пропуск имен каталогов начинающихся с '_' и '.',
    next unless -d "$directoryname/$subdirectoryname" && $subdirectoryname !~ /^(\.|_)/;

    if ($subdirectoryname =~ /$regexp/) {
        next if $excludenames;
    } else {
        next unless $excludenames;
    }
    
    opendir $SD, "$directoryname/$subdirectoryname" || die $!;
    
    print "$subdirectoryname\n";

    foreach my $inputfilename (readdir $SD) {   
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
                $entry[2] =~ s/\R/\n/g;
                $entry[3] =~ s/\R/\n/g;
                                
                #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  
                @data = unpack "C*", $entry[2];

                $inbuffer = {
                    'data'       => \@data,
                    'datalength' => scalar @data,
                    'index'      => 0
                };
                
                $document = node_create_document();     
                $context  = parser_initialize_context($inbuffer, $document);
                
                if ($entry[0] =~ /\bfragment\s+(\w+)\b/) {
                    $elementname = uc $1;
                    $element     = node_create_element(0, eval "\$ELEMENT_" . $elementname, $elementname, length $elementname);
                    parser_fragment($context, $element);
                } else {
                    parser_parse($context, $NULL);
                }
               
                if ($entry[0] =~ /\bserialize(\s+(\w+)\s+(\d+))?/) {
                    $text = $1 ? element_serialize($context->{'document'}{$2}, $3) :
                                 element_serialize($context->{'document'});
                } else {
                    $text = console_print_tree($context->{'document'}{'firstchild'});
                }
                #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
                
                $text =~ s/\R$//;
                $text =~ s/\R/\n/g;               
                
                if ($entry[3] ne $text) {
                    open $OF, ">$directoryname/$subdirectoryname/error($inputfilename.[$entry[1]]).txt" || die $!;

                    printf $OF "-%d-\n\n", $entry[1];
                    printf $OF "#%s\n",    $entry[0] if $entry[0];   
                    printf $OF "%s\n===>\n%s\n===>\n" . 
                                "\t!=\n"              . 
                                "<===\n%s\n<===",
                               $entry[2], $entry[3], $text;           
                               
                    if ($split) {
                        open $OF, ">$directoryname/$subdirectoryname/error($inputfilename.[$entry[1]]).a.txt" || die $!;
                        printf $OF "%s\n", $entry[3];

                        open $OF, ">$directoryname/$subdirectoryname/error($inputfilename.[$entry[1]]).b.txt" || die $!;
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

printf("--END--\n");

sub console_print_tree
{
    my ($node) = @_;
    my ($text, $space, $depth);
      
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
            
            $text .= sprintf "\n";              
        } elsif ($node->{'type'} == $NODE_TYPE_TEXT) {
            $text .= sprintf "%s\"%s\"\n", 
                             $space, $node->{'data'};
        } elsif ($node->{'type'} == $NODE_TYPE_COMMENT) {
            $text .= sprintf "%s!%s!\n", 
                             $space, $node->{'data'};
        } elsif ($node->{'type'} == $NODE_TYPE_DOCUMENT_TYPE) {
            $text .= sprintf "%s!%s\n", 
                             $space, uc $node->{'name'};
        }
        
        if ($node->{'firstchild'}) {
            $node  = $node->{'firstchild'};
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
    
    return $text;
}
