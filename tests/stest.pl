#===============================================================================
#       Тестирование сканера
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
use WebGear::HTML::Scanner;

my (
    @names, $excludenames, $regexp, $force, $split, 
    $D, $SD, $IF, $OF, $directoryname, $subdirectoryname, $inputfilename, 
    @entry, @data, 
    $text
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

$directoryname = "scanner";

opendir $D, $directoryname || die $!;

printf "%s\n%-20s %s     %s\n\n", "SUBDIR", "FILE", "LINE", "RESULT";

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
        # Пропуск имен файлов начинающихся с '_'.
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
                $text = sconsole_print_nodes(\@data, scalar @data, $entry[0]);
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

                printf "%20s %5s => %s\n", $inputfilename, $entry[1], $text;

                die if !$force && $text ne "OK";
            }
        }
    }
}

printf("--END--\n");

sub sconsole_print_nodes
{
    my ($data, $length, $parameters) = @_;
    my ($context, $text);
    
    $context = {
        'data'         => $data,
        'datalength'   => $length,
        'index'        => 0,

        'scannerstate' => \&scanner_state_text,  
        'nodeready'    => $FALSE,
        'node'         => $NULL,
        'rawswitch'    => $NULL
    };

    if ($parameters =~ /\b(script|title|textarea|style|xmp|iframe|noembed|noframes|noscript|plaintext|svg|math)\b/) {
        $context->{'rawswitch'} = {
            'chref' => $FALSE,
            'id'    => eval "\$ELEMENT_" . uc $1,
            'len'   => length $1,
            'name'  => [unpack "C*", $1]
        };

        if ($parameters =~ /script/) {
            $context->{'scannerstate'} = \&scanner_state_script;
        } elsif ($parameters =~ /plaintext/) {
            $context->{'scannerstate'} = \&scanner_state_plaintext;
        } elsif ($parameters =~ /svg|math/) {
            $context->{'scannerstate'} = \&scanner_state_foreigndata;
        } else {
            $context->{'scannerstate'} = \&scanner_state_rawdata;

            if ($parameters =~ /title|textarea/) {
                $context->{'rawswitch'}{'chref'} = $TRUE;
            }
        }
    }

    while (1) {

        if ($context->{'index'} >= $context->{'datalength'}) {
            $text .= sprintf "|*| .\n";
            last;
        }

        $context->{'scannerstate'}($context);
        $context->{'index'}++;

        next unless $context->{'nodeready'};

        if ($context->{'node'}{'type'} == $NODE_TYPE_START_TAG) {
            $text .= sprintf "|<| %s\n", $context->{'node'}{'id'}            ? 
                                         element_id_to_name($context->{'node'}{'id'}) :
                                         $context->{'node'}{'name'};

            foreach (sort keys %{$context->{'node'}{'attributes'}}) {
                $text .= sprintf "|A| %s\n", $context->{'node'}{'attributes'}{$_}{'id'}            ?
                                             attribute_id_to_name($context->{'node'}{'attributes'}{$_}{'id'}) :
                                             $context->{'node'}{'attributes'}{$_}{'name'};
                $text .= sprintf "|V| %s\n", $context->{'node'}{'attributes'}{$_}{'value'} if 
                                             $context->{'node'}{'attributes'}{$_}{'valuelength'};                
            }

        } elsif ($context->{'node'}{'type'} == $NODE_TYPE_END_TAG) {
            $text .= sprintf "|>| %s\n", $context->{'node'}{'id'}            ? 
                                         element_id_to_name($context->{'node'}{'id'}) :
                                         $context->{'node'}{'name'};
        } elsif ($context->{'node'}{'type'} == $NODE_TYPE_TEXT) {
            $text .= sprintf "|T| %s\n", $context->{'node'}{'data'};
        } elsif ($context->{'node'}{'type'} == $NODE_TYPE_COMMENT) {
            $text .= sprintf "|!| %s\n", $context->{'node'}{'data'};
        } elsif ($context->{'node'}{'type'} == $NODE_TYPE_DOCUMENT_TYPE) {
            $text .= sprintf "|D| %s, %s, %s\n", $context->{'node'}{'id'}               ?
                                                 documenttype_id_to_name($context->{'node'}{'id'})       :
                                                 $context->{'node'}{'name'},
                                                 $context->{'node'}{'publicid'}                   ?
                                                 documenttype_id_to_name($context->{'node'}{'publicid'}) :
                                                 $context->{'node'}{'public'},
                                                 $context->{'node'}{'systemid'}                   ?
                                                 documenttype_id_to_name($context->{'node'}{'systemid'}) :
                                                 $context->{'node'}{'system'};
        } else { die "??? $context->{'node'}{'type'} ???"; }

        $context->{'nodeready'} = $FALSE;
        #$context->{'node'}      = $NULL;
    }

    return $text;
}
