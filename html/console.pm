#===============================================================================
#       Отладочные подпрограммы
#===============================================================================

package WebGear::HTML::Console;
use strict;

use Exporter qw(import);
our @EXPORT = qw(
    console_print_scanner_state
    console_print_parser_state 
    console_print_node
    console_print_stack
    console_print_tree
    console_print_json_tree
);

use B;
# use Data::Dumper; 
use Scalar::Util qw(refaddr);

use WebGear::HTML::Constants;
use WebGear::HTML::DOM;
use WebGear::HTML::Tries;

sub console_print_scanner_state
{
    my ($context, $name) = @_;
    my ($char);
    # Если не указан выводимый текст, устанавливаме как имя текущего обработчика.
    $name = B::svref_2object($context->{'scannerstate'})->GV->NAME unless $name;
    $char = $context->{'inbuffer'}{'data'}[$context->{'inbuffer'}{'index'}];

    printf "===> sstate: %-49s [%0*d: '%c']\n",
           $name,
           length $context->{'inbuffer'}{'datalength'},
           $context->{'inbuffer'}{'index'},
           $char;
}

sub console_print_parser_state 
{
    my ($context, $text) = @_;
    
    $text = B::svref_2object($context->{'parserstate'})->GV->NAME unless $text;
          
    printf "===> pstate: %-22s [", $text;
 
    if ($context->{'node'}{'type'} == $NODE_TYPE_START_TAG ||
        $context->{'node'}{'type'} == $NODE_TYPE_END_TAG) {
        printf "%s%s", 
               $context->{'node'}{'type'} == $NODE_TYPE_START_TAG ? "<" : ">",
               $context->{'node'}{'id'} ? element_id_to_name($context->{'node'}{'id'}) :
               $context->{'node'}{'name'};
    } elsif ($context->{'node'}{'type'} == $NODE_TYPE_TEXT || $context->{'node'}{'type'} == $NODE_TYPE_COMMENT) {
        printf "'%s'", text_clean($context->{'node'}{'data'});
    } elsif ($context->{'node'}{'type'} == $NODE_TYPE_EOF) {
        printf "*EOF*";
    }  else {
        die "$context->{'node'}{'type'}?\n";
    }
    
    printf "] quirks:%d, frameset:%d\n", 
           $context->{'flags'} & ($PARSER_FLAG_QUIRKS_MODE_QUIRKS | $PARSER_FLAG_QUIRKS_MODE_LIMITED),
           $context->{'flags'} & $PARSER_FLAG_FRAMESET_OK; 
           
    # console_print_stack($context, "afe");
    # console_print_stack($context, "soe");
    # printf("\n");
    # console_print_tree($context, $context->{'document'}{'firstchild'});
    # printf("\n");
}

sub console_print_stack
{
    my ($context, $name, $extra) = @_; # 'r'evers, 'a'ddress
    my ($element);
    
    printf "\t%s%s: ", $name, $extra =~ /r/ ? "(r)" : "";
    
    $element = $context->{$name};
        
    while ($element) {
    
        if ($extra =~ /r/) {
            printf "%s%s%s%s", 
                   $element->{'next' . $name . 'node'} ? "->" : "",
                   $element->{'id'} ? element_id_to_name($element->{'id'}) : 
                   $element->{'name'},
                   $name eq "afe" && $element->{'afemarkers'} ? "*($element->{'afemarkers'})" : "",
                   $extra =~ /a/ ? "(" . refaddr($element) . ")": "";
        } 
        # Выход на последнем элементе для возможного обратного прохода.
        last unless $element->{'previous' . $name . 'node'};
        $element = $element->{'previous' . $name . 'node'};
    }
    
    unless ($extra =~ /r/) {
    
        while ($element) {
            printf "%s%s%s%s", 
                   $element->{'previous' . $name . 'node'} ? "->" : "",
                   $element->{'id'} ? element_id_to_name($element->{'id'}) : 
                   $element->{'name'},
                   $name eq "afe" && $element->{'afemarkers'} ? "*($element->{'afemarkers'})" : "",
                   $extra =~ /a/ ? "(" . refaddr($element) . ")": "";
            $element = $element->{'next' . $name . 'node'};
        }
    }
    
    printf("\n");
}

sub console_print_node
{
    my ($node) = @_;
    my ($data);
    # print Dumper($context->{'node'});
    printf "node> type: ";

    if ($node->{'type'} == $NODE_TYPE_START_TAG) {
        printf "NODE_TYPE_STARTTAG %s\n" .
               "      name: %s (%d), %d:'%s'\n",
               $node->{'flags'} & $NODE_FLAG_SELFCLOSING ? "(NODE_FLAG_SELF_CLOSING)" : "",
               element_id_to_name($node->{'id'}),
               $node->{'id'},
               $node->{'name'},
               $node->{'namelength'};

        if (%{$node->{'attributes'}}) {
            print "--- attributes ---\n";

            foreach (sort keys %{$node->{'attributes'}}) {
                printf "      name: %s (%d), %d:'%s'\n" .
                       "     value: %d:'%s'\n",
                       attribute_id_to_name($node->{'attributes'}{$_}{'id'}),
                       $node->{'attributes'}{$_}{'id'},
                       $node->{'attributes'}{$_}{'namelength'},
                       $node->{'attributes'}{$_}{'name'},
                       $node->{'attributes'}{$_}{'valuelength'},
                       $node->{'attributes'}{$_}{'value'};
            }
        }

        if (%{$node->{'events'}}) {
            print "--- events ---\n";

            foreach (sort keys %{$node->{'events'}}) {
                printf "      type: %s (%d), %d:'%s'\n" .
                       "  function: %d:'%s'\n",
                       event_id_to_name($node->{'events'}{$_}{'id'}),
                       $node->{'events'}{$_}{'id'},
                       $node->{'events'}{$_}{'typelength'},
                       $node->{'events'}{$_}{'type'},
                       $node->{'events'}{$_}{'functionlength'},
                       $node->{'events'}{$_}{'function'};
            }
        }

    } elsif ($node->{'type'} == $NODE_TYPE_TEXT || $node->{'type'} == $NODE_TYPE_COMMENT) {
        printf "%s %s\n" .
               "       data: %d:'%s'\n",
               $node->{'type'}  == $NODE_TYPE_TEXT ? "NODE_TYPE_TEXT" : "NODE_TYPE_COMMENT",
               $node->{'flags'}  & $NODE_FLAG_WHITESPACE ? "(TOKEN_FLAG_WHITESPACE)" : "",
               $node->{'datalength'},
               text_clean($node->{'data'});
    } elsif ($node->{'type'} == $NODE_TYPE_DOCUMENT_TYPE) {
        printf "TOKEN_TYPE_DOCTYPE%s\n"    .
               "      name: (%d) %d:'%s'\n" .
               "    public: (%d) %d:'%s'\n" .
               "    system: (%d) %d:'%s'\n",
               $node->{'flags'} & $NODE_FLAG_FORCE_QUIRKS ? ", TOKEN_FLAG_FORCE_QUIRKS" : "",
               $node->{'id'},
               $node->{'name'},
               $node->{'namelength'},
               $node->{'publicid'},
               $node->{'publiclength'},
               $node->{'public'},
               $node->{'systemid'},
               $node->{'systemlength'},
               $node->{'system'};
    # Далее идут вспомогательные узлы не относящиеся к DOM.
    } elsif ($node->{'type'} == $NODE_TYPE_END_TAG) {
        printf "NODE_TYPE_END_TAG %s\n" .
               "      name: %s (%d), %d:'%s'\n",
               $node->{'flags'} & $NODE_FLAG_SELFCLOSING ? "(NODE_FLAG_SELF_CLOSING)" : "",
               element_id_to_name($node->{'id'}),
               $node->{'id'},
               $node->{'namelength'},
               $node->{'name'};
    } elsif ($node->{'type'} == $NODE_TYPE_EOF)  {
        printf "NODE_TYPE_EOF\n";
    } else {
        die "$node->{'type'}?\n";
    }
}

sub console_print_tree
{
    my ($node, $extra) = @_;
    my ($space, $depth, $event);

    $depth = 0;
    
    while (1) {    
    
        if ($extra =~ /s/) {
        
            if ($node->{'type'} == $NODE_TYPE_ELEMENT) {
                printf "%s%s\n", 
                       $space, $node->{'id'} ? element_id_to_name($node->{'id'}) : $node->{'name'};  
            } 
            
        } else {
            printf "%s~~~~~~~~~~~~~~~~~~~~~~~~~~\n%s[%07x]\n" .
                   "%sobj       > %07x\n"                     .
                   "%stype      > %d\n"                       .
                   "%sparent    > %07x\n"                     . 
                   "%ssibling   > %07x-%07x\n", 
                   $space, $space, refaddr($node),
                   $space, $node->{'object'},
                   $space, $node->{'type'},
                   $space, refaddr($node->{'parent'}),
                   $space, refaddr($node->{'previoussibling'}), 
                           refaddr($node->{'nextsibling'}); 
            
            if ($node->{'type'} == $NODE_TYPE_ELEMENT) {
                printf "%schild     > %07x-%07x\n"       .
                       "%ssoe       > %07x-%07x\n"       .
                       "%safe       > %07x-%07x *(%d)\n" . 
                       "%sname      : %s (%d), %d:'%s'\n", 
                       $space, refaddr($node->{'firstchild'}),  
                               refaddr($node->{'lastchild'}),  
                       $space, refaddr($node->{'soeprevious'}),     
                               refaddr($node->{'soenext'}),
                       $space, refaddr($node->{'afeprevious'}),     
                               refaddr($node->{'afenext'}), 
                               $node->{'afemarkers'},
                       $space, element_id_to_name($node->{'id'}), 
                               $node->{'id'}, 
                               $node->{'namelength'}, 
                               $node->{'name'};
       
                foreach (sort keys %{$node->{'attributes'}}) {
                    printf "%sattribute : %d:'%s'=%d:'%s'\n", 
                           $space, $node->{'attributes'}{$_}{'namelength'},
                                   $node->{'attributes'}{$_}{'name'},
                                   $node->{'attributes'}{$_}{'valuelength'},
                                   text_clean($node->{'attributes'}{$_}{'value'});
                }    
            
                foreach (sort keys %{$node->{'events'}}) {
                    printf "%sevent     : %d:'%s'=%d:'%s':[%07x], %d\n", 
                           $space, $node->{'events'}{$_}{'typelength'},
                                   $node->{'events'}{$_}{'type'},
                                   $node->{'events'}{$_}{'functionlength'},
                                   text_clean($node->{'events'}{$_}{'function'}),
                                   $node->{'events'}{$_}{'callback'},
                                   $node->{'events'}{$_}{'flags'};
                }    
            
            } elsif ($node->{'type'} == $NODE_TYPE_TEXT) {  
                printf "%stext      : %d:'%s'\n", 
                        $space, $node->{'datalengh'}, text_clean($node->{'data'});
            } elsif ($node->{'type'} == $NODE_TYPE_COMMENT) {
                printf "%scomment   : %d:'%s'\n", 
                        $space, $node->{'datalengh'}, text_clean($node->{'data'});
            } elsif ($node->{'type'} == $NODE_TYPE_DOCUMENT_TYPE) {        
                printf "%sdoctype   : %d:'%s', %d:'%s', %d:'%s'\n",
                       $space, $node->{'namelength'}, 
                               $node->{'name'},    
                               $node->{'publiclength'}, 
                               $node->{'public'},
                               $node->{'systemlength'}, 
                               $node->{'system'};
            } 
        }
        # Дочерние узлы есть только у элементов и документа.  
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
        # Выход на нулевой глубине.
        if (!$depth) {
            last;
        }
        # sprintf("%*s", --$depth * 2, ' ') при нулевой глубине дает единичный пробел.
        $space = ' ' x (--$depth * 2);
         
        if ($node = $node->{'parent'}) {
            goto L;
        }
   }
}

sub console_print_json_tree
{
    my ($node) = @_;
    my ($space, $depth, $text, $json, @keys, $index);

    $depth = 0;

    while (1) {   
        $text = '';    
        $json = '';

        printf("%s{\n%s\"node\": \"%s\"", $space, $space, refaddr($node));      

        if ($node->{'type'} == $NODE_TYPE_ELEMENT) {
            $text = sprintf ",\n%s\"tag\": \"%s (%d), '%s'\"",
                            $space, element_id_to_name($node->{'id'}), 
                                    $node->{'id'},
                                    json_clean($node->{'name'});
            # Вывод обработчиков событытий пока не реализован. 
            @keys = sort keys %{$node->{'attributes'}};
            
            if (@keys) {
                $text .= sprintf ",\n%s\"attributes\": [", $space;
            
                for (my $index = 0; $index < @keys; $index++) {       
                    $text .= sprintf "\n%s  {\"%s\": \"%s\"}", 
                                     $space, json_clean($node->{'attributes'}{$keys[$index]}{'name'}),
                                             json_clean($node->{'attributes'}{$keys[$index]}{'value'});
                    
                    if ($index < @keys - 1) {
                        $text .= sprintf ",";
                    }
                }    
                
                $text .= sprintf "\n%s]", $space;
            }
            
            @keys = sort keys %{$node->{'events'}};
            
            if (@keys) {
                $text .= sprintf ",\n%s\"events\": [", $space;
            
                for (my $index = 0; $index < @keys; $index++) {       
                    $text .= sprintf "\n%s  {\"%s\": \"%s\"}", 
                                     $space, json_clean($node->{'events'}{$keys[$index]}{'type'}),
                                             json_clean($node->{'events'}{$keys[$index]}{'function'});
                    
                    if ($index < @keys - 1) {
                        $text .= sprintf ",";
                    }
                }    
                
                $text .= sprintf "\n%s]", $space;
            }
 
        } elsif ($node->{'type'} == $NODE_TYPE_TEXT) {
            $text = sprintf ",\n%s\"text\": \"%s\"", 
                            $space, json_clean($node->{'data'});                   
        } elsif ($node->{'type'} == $NODE_TYPE_COMMENT) {
            $text = sprintf ",\n%s\"comment\": \"%s\"", 
                            $space, json_clean($node->{'data'});     
        } elsif ($node->{'type'} == $NODE_TYPE_DOCUMENT_TYPE) {
            $text = sprintf ",\n%s\"doctype\": \"'%s', '%s', '%s'\"", 
                            $space, $node->{'name'},
                                    $node->{'public'},
                                    $node->{'system'};    
        } else {
            #$text  = sprintf("\"??? %d\": ", $node->{'type'});
            #$json = sprintf("%s", text($node->{'token'}{'i'}, $node->{'token.len'}));
        }

        printf "%s", $text; 
        
        if ($node->{'firstchild'}) {
            printf ",\n%s\"childs\": [\n", $space;
            $node  = $node->{'firstchild'};
            $space = ' ' x (++$depth * 2);
            next;
        } 
    L:    
        printf "\n%s}\n", $space;
   
        if ($node->{'nextsibling'}) {
            printf "%s,\n", $space;
            $node = $node->{'nextsibling'};
            next;
        }
        
        if (!$depth) {
            last;
        }
        
        $space = ' ' x (--$depth * 2);
        
        if ($node = $node->{'parent'}) {
 
            if ($node->{'firstchild'}) {
                printf "%s]", $space;
            }

            goto L;
        }
    }
}

sub json_clean 
{
    my ($text) = @_;
    # Unicode definition of a control character.
    $text =~ s/[\x00-\x1f\x7f-\x9f]/ /g;
    $text =~ s/(\\|\")/\\$1/g;
    
    return $text;
}

sub text_clean 
{
    my ($text) = @_;
    
    $text =~ s/\R/\\n/g;
    
    return $text;
}

1;