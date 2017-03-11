#===============================================================================
#       Парсер
#===============================================================================

package WebGear::HTML::Parser;
use strict;

use Exporter qw(import);
our @EXPORT = qw(
    parser_initialize_context
    parser_parse
    parser_fragment
);

use WebGear::HTML::Filter;
use WebGear::HTML::Constants;
use WebGear::HTML::AAA;
use WebGear::HTML::DOM;
# use WebGear::HTML::Console;
use WebGear::HTML::Scanner;
use WebGear::HTML::Stacks;
use WebGear::HTML::Tries;
use WebGear::HTML::Utilities;

sub parser_initialize_context
{
    my ($document, $context);

    $document = node_create_document();

    $context = {
        'flags'        => $PARSER_FLAG_FRAMESET_OK,

        'data'         => $NULL,
        'datalength'   => 0,
        'index'        => 0,

        'scannerstate' => $NULL,
        'parserstate'  => $NULL,

        'nodeready'    => 0,
        'node'         => $NULL,

        'rawswitch'    => $NULL,

        'document'     => $document,

        'form'         => $NULL,
        'context'      => $NULL,

        'afe'          => $NULL,
        # Вставляем корневой элемент в SOE напрямую.
        'soe'          => $document,
        'sti'          => [],

        'jscontext'    => $NULL,
        'jscallback'   => $NULL
    };

    return $context;
}

sub parser_parse
{
    my ($context, $data, $datalength, $jscontext, $jscallback) = @_;
    
    $context->{'data'}         = $data;
    $context->{'datalength'}   = $datalength;
    $context->{'scannerstate'} = \&scanner_state_text;
    $context->{'parserstate'}  = \&parser_state_initial;
    $context->{'jscontext'}    = $jscontext;
    $context->{'jscallback'}   = $jscallback;

    parser_process($context);
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# https://html.spec.whatwg.org/multipage/syntax.html#html-fragment-parsing-algorithm
# https://www.w3.org/TR/html/syntax.html#parsing-html-fragments
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub parser_fragment
{
    my ($context, $data, $datalength, $contextelementid, $contextelementname, $contextelementnamelength) = @_;
    my ($element);

    $context->{'data'}       = $data;
    $context->{'datalength'} = $datalength;

    if ($contextelementid == $ELEMENT_IFRAME) {
        $context->{'rawswitch'}    = $raw[0];
        $context->{'scannerstate'} = $context->{'rawswitch'}{'state'};
    } elsif ($contextelementid == $ELEMENT_MATH) { 
        $context->{'rawswitch'}    = $raw[1];
        $context->{'scannerstate'} = $context->{'rawswitch'}{'state'};
    } elsif ($contextelementid == $ELEMENT_NOEMBED) {
        $context->{'rawswitch'}    = $raw[2];
        $context->{'scannerstate'} = $context->{'rawswitch'}{'state'};
    } elsif ($contextelementid == $ELEMENT_NOFRAMES) { 
        $context->{'rawswitch'}    = $raw[3];
        $context->{'scannerstate'} = $context->{'rawswitch'}{'state'};
    } elsif ($contextelementid == $ELEMENT_NOSCRIPT) { 
        $context->{'rawswitch'}    = $raw[4];
        $context->{'scannerstate'} = $context->{'rawswitch'}{'state'};
    } elsif ($contextelementid == $ELEMENT_PLAINTEXT) {
        $context->{'rawswitch'}    = $raw[5];
        $context->{'scannerstate'} = $context->{'rawswitch'}{'state'};
    } elsif ($contextelementid == $ELEMENT_SCRIPT && $context->{'jscontext'} && $context->{'jscallback'}) { 
        $context->{'rawswitch'}    = $raw[6];
        $context->{'scannerstate'} = $context->{'rawswitch'}{'state'};
    } elsif ($contextelementid == $ELEMENT_STYLE) {
        $context->{'rawswitch'}    = $raw[7];
        $context->{'scannerstate'} = $context->{'rawswitch'}{'state'};
    } elsif ($contextelementid == $ELEMENT_SVG) {
        $context->{'rawswitch'}    = $raw[8];
        $context->{'scannerstate'} = $context->{'rawswitch'}{'state'};
    } elsif ($contextelementid == $ELEMENT_TEXTAREA) {
        $context->{'rawswitch'}    = $raw[9];
        $context->{'scannerstate'} = $context->{'rawswitch'}{'state'};
    } elsif ($contextelementid == $ELEMENT_TITLE) {
        $context->{'rawswitch'}    = $raw[10];
        $context->{'scannerstate'} = $context->{'rawswitch'}{'state'};
    } elsif ($contextelementid == $ELEMENT_XMP) {
        $context->{'rawswitch'}    = $raw[11];
        $context->{'scannerstate'} = $context->{'rawswitch'}{'state'};
    } else {
        $context->{'scannerstate'} = \&scanner_state_text;

        if ($contextelementid == $ELEMENT_TEMPLATE) {
            sti_push($context, \&parser_state_in_template);
        }
    }

    $element = node_create_element(0, $ELEMENT_HTML, '', 0);
    $context->{'document'}{'html'} = $element;
    
    node_append($context->{'document'}, $element);
    soe_push($context, $element);

    $element = node_create_element(0, $contextelementid, $contextelementname, $contextelementnamelength);
    $context->{'context'} = $element;

    parser_reset_insertion_mode($context);
    # Устанавливаем элемент текущим узлом сканера.
    $context->{'nodeready'} = $TRUE;
    $context->{'node'}      = $element;

    parser_process($context);
}

sub parser_process
{
    my ($context) = @_;
    # EOF обнуляет поле текущего состояния парсера.
    while ($context->{'parserstate'}) {

        while (!$context->{'nodeready'}) {

            if (!n(0)) {
                $context->{'node'} = node_create_eof();
                last;
            }

            $context->{'scannerstate'}($context);
            $context->{'index'}++;
        }

        $context->{'nodeready'} = $FALSE;
        $context->{'parserstate'}($context);
        # Указатель на узел не обнуляется.
    }
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# https://html.spec.whatwg.org/multipage/syntax.html#reset-the-insertion-mode-appropriately
# https://www.w3.org/TR/html/syntax.html#reset-the-insertion-mode-appropriately
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub parser_reset_insertion_mode
{
    my ($context) = @_;
    my ($last, $element);

    $last    = $FALSE;
    $element = $context->{'soe'};

    while ($element) {
        # Учитываем, что первым узлом в стеке являетcя DOCUMENT.
        if ($element->{'id'} == $ELEMENT_HTML) {
            $last = $TRUE;

            if ($context->{'context'}) {
                $element = $context->{'context'};
            }
        }

        if ($element->{'id'} == $ELEMENT_SELECT) {

            if (!$last) {

                while (1) {
                    $element = $element->{'soeprevious'};

                    if (!$element || $element->{'id'} == $ELEMENT_TEMPLATE) {
                        last;
                    }

                    if ($element->{'id'} == $ELEMENT_TABLE) {
                        $context->{'parserstate'} = \&parser_state_in_select_in_table;
                        return;
                    }
                }
            }

            $context->{'parserstate'} = \&parser_state_in_select;
            return;
        }

        if ($element->{'id'} == $ELEMENT_TR) {
            $context->{'parserstate'} = \&parser_state_in_row;
            return;
        }

        if ($element->{'id'} == $ELEMENT_TBODY ||
            $element->{'id'} == $ELEMENT_TFOOT ||
            $element->{'id'} == $ELEMENT_THEAD) {
            $context->{'parserstate'} = \&parser_state_in_table_body;
            return;
        }

        if ($element->{'id'} == $ELEMENT_CAPTION) {
            $context->{'parserstate'} = \&parser_state_in_caption;
            return;
        }

        if ($element->{'id'} == $ELEMENT_COLGROUP) {
            $context->{'parserstate'} = \&parser_state_in_column_group;
            return;
        }

        if ($element->{'id'} == $ELEMENT_TABLE) {
            $context->{'parserstate'} = \&parser_state_in_table;
            return;
        }

        if ($element->{'id'} == $ELEMENT_TEMPLATE) {
            $context->{'parserstate'} = $context->{'sti'}[-1];
            return;
        }

        if ($element->{'id'} == $ELEMENT_BODY) {
            $context->{'parserstate'} = \&parser_state_in_body;
            return;
        }

        if ($element->{'id'} == $ELEMENT_FRAMESET) {
            $context->{'parserstate'} = \&parser_state_in_frameset;
            return;
        }

        if ($element->{'id'} == $ELEMENT_HTML) {

            if ($context->{'document'}{'head'}) {
                $context->{'parserstate'} = \&parser_state_after_head;
            } else {
                $context->{'parserstate'} = \&parser_state_before_head;
            }

            return;
        }

        if (!$last) {

            if ($element->{'id'} == $ELEMENT_TD ||
                $element->{'id'} == $ELEMENT_TH) {
                $context->{'parserstate'} = \&parser_state_in_cell;
                return;
            }

            if ($element->{'id'} == $ELEMENT_HEAD) {
                $context->{'parserstate'} = \&parser_state_in_head;
                return;
            }

        } else {
            last;
        }

        $element = $element->{'soeprevious'};
    }
    # Вынесено за цикл на случай нулевого элемента, который не должен возникнуть в принципе.
    $context->{'parserstate'} = \&parser_state_in_body;
}

#----- Состояния парсера -------------------------------------------------------
# Везде где после проверки элемента на вхождение в область видимости идет:
# * Generate implied end tags/Generate all implied end tags thoroughly.
# * Pop elements from the stack of open elements until a <ИМЯ> element has been
#   popped from the stack.
# шаг "Generate..." не используется.
#-------------------------------------------------------------------------------

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# https://html.spec.whatwg.org/multipage/syntax.html#the-initial-insertion-mode
# https://www.w3.org/TR/html/syntax.html#the-initial-insertion-mode
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub parser_state_initial
{
    my ($context) = @_;

    if ($context->{'node'}{'type'}  == $NODE_TYPE_TEXT &&
        $context->{'node'}{'flags'}  & $NODE_FLAG_WHITESPACE) {
        return;
    }

    if ($context->{'node'}{'type'} == $NODE_TYPE_COMMENT) {
        node_append($context->{'document'}, $context->{'node'});
        return;
    }
    
    $context->{'parserstate'} = \&parser_state_before_html;

    if ($context->{'node'}{'type'} == $NODE_TYPE_DOCUMENT_TYPE) {
        $context->{'document'}{'documenttype'} = $context->{'node'};
    
        node_append($context->{'document'}, $context->{'node'});

        if ($context->{'node'}{'flags'}  & $NODE_FLAG_FORCE_QUIRKS ||
            $context->{'node'}{'id'}    != $DOCUMENTTYPE_HTML       ||
            $context->{'node'}{'publicid'}                          ||
            $context->{'node'}{'systemid'}) {

            if ($context->{'node'}{'publicid'} == $DOCUMENTTYPE_W3CDTDXHTML10FRAMESET     ||
                $context->{'node'}{'publicid'} == $DOCUMENTTYPE_W3CDTDXHTML10TRANSITIONAL ||
                $context->{'node'}{'publicid'} == $DOCUMENTTYPE_W3CDTDHTML401FRAMESET     ||
                $context->{'node'}{'publicid'} == $DOCUMENTTYPE_W3CDTDHTML401TRANSITIONAL) {
                $context->{'flags'} |= $PARSER_FLAG_QUIRKS_MODE_LIMITED;
            } else {
                $context->{'flags'} |= $PARSER_FLAG_QUIRKS_MODE_QUIRKS;
            }
        }

        return;
    }

    $context->{'flags'}     |= $PARSER_FLAG_QUIRKS_MODE_QUIRKS;
    $context->{'nodeready'}  = $TRUE;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# https://html.spec.whatwg.org/multipage/syntax.html#the-before-html-insertion-mode
# https://www.w3.org/TR/html/syntax.html#the-before-html-insertion-mode
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub parser_state_before_html
{
    my ($context) = @_;
    my ($element);

    if ($context->{'node'}{'type'}  == $NODE_TYPE_DOCUMENT_TYPE ||
       ($context->{'node'}{'type'}  == $NODE_TYPE_TEXT          &&
        $context->{'node'}{'flags'}  & $NODE_FLAG_WHITESPACE)) {
        return;
    }

    if ($context->{'node'}{'type'} == $NODE_TYPE_COMMENT) {
        node_append($context->{'document'}, $context->{'node'});
        return;
    }

    if ($context->{'node'}{'type'} == $NODE_TYPE_START_TAG) {

        if ($context->{'node'}{'id'} == $ELEMENT_HTML) {
            $context->{'document'}{'html'} = $context->{'node'};
        
            node_append($context->{'document'}, $context->{'node'});
            soe_push($context, $context->{'node'});

            $context->{'parserstate'} = \&parser_state_before_head;
            return;
        }

    } elsif ($context->{'node'}{'type'} == $NODE_TYPE_END_TAG) {

        if ($context->{'node'}{'id'} != $ELEMENT_HEAD &&
            $context->{'node'}{'id'} != $ELEMENT_BODY &&
            $context->{'node'}{'id'} != $ELEMENT_HTML &&
            $context->{'node'}{'id'} != $ELEMENT_BR) {
            return;
        }
    }

    $element = node_create_element(0, $ELEMENT_HTML, '', 0);
    $context->{'document'}{'html'} = $element;
    
    node_append($context->{'document'}, $element);
    soe_push($context, $element);

    $context->{'document'}{'html'} = $element;
    $context->{'parserstate'} = \&parser_state_before_head;
    $context->{'nodeready'}   = $TRUE;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# https://html.spec.whatwg.org/multipage/syntax.html#the-before-head-insertion-mode
# https://www.w3.org/TR/html/syntax.html#the-before-head-insertion-mode
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub parser_state_before_head
{
    my ($context) = @_;
    my ($element);

    if ($context->{'node'}{'type'}  == $NODE_TYPE_DOCUMENT_TYPE ||
       ($context->{'node'}{'type'}  == $NODE_TYPE_TEXT         &&
        $context->{'node'}{'flags'}  & $NODE_FLAG_WHITESPACE)) {
        return;
    }

    if ($context->{'node'}{'type'} == $NODE_TYPE_COMMENT) {
        node_insert($context, $context->{'soe'}, $context->{'node'});
        return;
    }

    if ($context->{'node'}{'type'} == $NODE_TYPE_START_TAG) {

        if ($context->{'node'}{'id'} == $ELEMENT_HTML) {
            parser_state_in_body($context);
            return
        }

        if ($context->{'node'}{'id'} == $ELEMENT_HEAD) {
            $context->{'document'}{'head'} = $context->{'node'};
            
            node_insert($context, $context->{'soe'}, $context->{'node'});
            soe_push($context, $context->{'node'});

            $context->{'parserstate'} = \&parser_state_in_head;
            return;
        }

    } elsif ($context->{'node'}{'type'} == $NODE_TYPE_END_TAG) {

        if ($context->{'node'}{'id'} != $ELEMENT_HEAD &&
            $context->{'node'}{'id'} != $ELEMENT_BODY &&
            $context->{'node'}{'id'} != $ELEMENT_HTML &&
            $context->{'node'}{'id'} != $ELEMENT_BR) {
            return;
        }
    }

    $element = node_create_element(0, $ELEMENT_HEAD, '', 0);
    $context->{'document'}{'head'} = $element;
    
    node_insert($context, $context->{'soe'}, $element);
    soe_push($context, $element);

    $context->{'document'}{'head'} = $element;
    $context->{'parserstate'} = \&parser_state_in_head;
    $context->{'nodeready'}   = $TRUE;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# https://html.spec.whatwg.org/multipage/syntax.html#parsing-main-inhead
# https://www.w3.org/TR/html/syntax.html#the-in-head-insertion-mode
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub parser_state_in_head
{
    my ($context) = @_;
    my ($element);

    if ($context->{'node'}{'type'} == $NODE_TYPE_DOCUMENT_TYPE) {
        return;
    }

    if ($context->{'node'}{'type'}  == $NODE_TYPE_COMMENT ||
       ($context->{'node'}{'type'}  == $NODE_TYPE_TEXT    &&
        $context->{'node'}{'flags'}  & $NODE_FLAG_WHITESPACE)) {
        node_insert($context, $context->{'soe'}, $context->{'node'});
        return
    }

    if ($context->{'node'}{'type'} == $NODE_TYPE_START_TAG) {

        if ($context->{'node'}{'id'} == $ELEMENT_HTML) {
            parser_state_in_body($context);
            return;
        }
        # VOID
        if ($context->{'node'}{'id'} == $ELEMENT_BASE     ||
            $context->{'node'}{'id'} == $ELEMENT_BASEFONT ||
            $context->{'node'}{'id'} == $ELEMENT_BGSOUND  ||
            $context->{'node'}{'id'} == $ELEMENT_LINK) {
            node_insert($context, $context->{'soe'}, $context->{'node'});
            return;
        }
        # VOID
        if ($context->{'node'}{'id'} == $ELEMENT_META) {
            node_insert($context, $context->{'soe'}, $context->{'node'});

            if (attribute_contain($context->{'node'}, 'charset', 'name')            ||
                attribute_contain($context->{'node'}, 'http-equiv', 'content-type') ||
                exists $context->{'node'}{'attributes'}{'content'}) {
                # print "UNDER CONSTRUCTION";
            }

            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_TITLE) {
            $context->{'document'}{'title'} = $context->{'node'};
            
            node_insert($context, $context->{'soe'}, $context->{'node'});
            element_append_rawdata($context, $context->{'node'});
            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_NOSCRIPT) {
            node_insert($context, $context->{'soe'}, $context->{'node'});

            if ($context->{'jscontext'} && $context->{'jscallback'}) {
                element_append_rawdata($context, $context->{'node'});
            } else {
                soe_push($context, $context->{'node'});
                $context->{'parserstate'} = \&parser_state_in_head_noscript;
            }

            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_NOFRAMES ||
            $context->{'node'}{'id'} == $ELEMENT_STYLE) {
            node_insert($context, $context->{'soe'}, $context->{'node'});
            element_append_rawdata($context, $context->{'node'});
            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_SCRIPT) {
            $element = $context->{'node'};
        
            node_insert($context, $context->{'soe'}, $context->{'node'});
            element_append_rawdata($context, $context->{'node'});
              
            if ($context->{'jscontext'} && $context->{'jscallback'}) {
                $context->{'jscallback'}($context->{'jscontext'}, $element->{'firstchild'}{'data'}, $element->{'firstchild'}{'datalength'});
            }
            
            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_TEMPLATE) {
            node_insert($context, $context->{'soe'}, $context->{'node'});
            soe_push($context, $context->{'node'});
            sti_push($context, \&parser_state_in_template);
            afe_insert_marker($context);

            $context->{'flags'}       &= ~$PARSER_FLAG_FRAMESET_OK;
            $context->{'parserstate'}  = \&parser_state_in_template;
            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_HEAD) {
            return;
        }

    } elsif ($context->{'node'}{'type'} == $NODE_TYPE_END_TAG) {

        if ($context->{'node'}{'id'} == $ELEMENT_HEAD) {
            soe_pop($context);

            $context->{'parserstate'} = \&parser_state_after_head;
            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_TEMPLATE) {

            if (soe_search_id($context, $ELEMENT_TEMPLATE)) {
                soe_pop_until_id($context, $ELEMENT_TEMPLATE);
                afe_clear($context);
                sti_pop($context);
                parser_reset_insertion_mode($context);
            }

            return;
        }

        if ($context->{'node'}{'id'} != $ELEMENT_BODY &&
            $context->{'node'}{'id'} != $ELEMENT_HTML &&
            $context->{'node'}{'id'} != $ELEMENT_BR) {
            return;
        }
    }

    soe_pop($context);

    $context->{'parserstate'} = \&parser_state_after_head;
    $context->{'nodeready'}   = $TRUE;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# https://html.spec.whatwg.org/multipage/syntax.html#parsing-main-inheadnoscript
# https://www.w3.org/TR/html/syntax.html#the-in-head-noscript-insertion-mode
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub parser_state_in_head_noscript
{
    my ($context) = @_;

    if ($context->{'node'}{'type'} == $NODE_TYPE_DOCUMENT_TYPE) {
        return;
    }

    if ($context->{'node'}{'type'}  == $NODE_TYPE_COMMENT ||
       ($context->{'node'}{'type'}  == $NODE_TYPE_TEXT    &&
        $context->{'node'}{'flags'}  & $NODE_FLAG_WHITESPACE)) {
        parser_state_in_head($context);
        return;
    }

    if ($context->{'node'}{'type'} == $NODE_TYPE_START_TAG) {

        if ($context->{'node'}{'id'} == $ELEMENT_HTML) {
            parser_state_in_body($context);
            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_BASEFONT ||
            $context->{'node'}{'id'} == $ELEMENT_BGSOUND  ||
            $context->{'node'}{'id'} == $ELEMENT_LINK     ||
            $context->{'node'}{'id'} == $ELEMENT_META     ||
            $context->{'node'}{'id'} == $ELEMENT_NOFRAMES ||
            $context->{'node'}{'id'} == $ELEMENT_STYLE) {
            parser_state_in_head($context);
            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_HEAD ||
            $context->{'node'}{'id'} == $ELEMENT_NOSCRIPT) {
            return;
        }

    } elsif ($context->{'node'}{'type'} == $NODE_TYPE_END_TAG) {

        if ($context->{'node'}{'id'} == $ELEMENT_NOSCRIPT) {
            soe_pop($context);

            $context->{'parserstate'} = \&parser_state_in_head;
            return;
        }

        if ($context->{'node'}{'id'} != $ELEMENT_BR) {
            return;
        }
    }

    soe_pop($context);

    $context->{'parserstate'} = \&parser_state_in_head;
    $context->{'nodeready'}   = $TRUE;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# https://html.spec.whatwg.org/multipage/syntax.html#the-after-head-insertion-mode
# https://www.w3.org/TR/html/syntax.html#the-after-head-insertion-mode
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub parser_state_after_head
{
    my ($context) = @_;
    my ($element);

    if ($context->{'node'}{'type'} == $NODE_TYPE_DOCUMENT_TYPE) {
        return;
    }

    if ($context->{'node'}{'type'}  == $NODE_TYPE_COMMENT ||
       ($context->{'node'}{'type'}  == $NODE_TYPE_TEXT    &&
        $context->{'node'}{'flags'}  & $NODE_FLAG_WHITESPACE)) {
        node_insert($context, $context->{'soe'}, $context->{'node'});
        return;
    }

    if ($context->{'node'}{'type'} == $NODE_TYPE_START_TAG) {

        if ($context->{'node'}{'id'} == $ELEMENT_HTML) {
            parser_state_in_body($context);
            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_BODY) {
            $context->{'document'}{'body'} = $context->{'node'};
            
            node_insert($context, $context->{'soe'}, $context->{'node'});
            soe_push($context, $context->{'node'});

            $context->{'flags'} &= ~$PARSER_FLAG_FRAMESET_OK;

            $context->{'parserstate'} = \&parser_state_in_body;
            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_FRAMESET) {
            node_insert($context, $context->{'soe'}, $context->{'node'});
            soe_push($context, $context->{'node'});

            $context->{'parserstate'} = \&parser_state_in_frameset;
            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_BASE     ||
            $context->{'node'}{'id'} == $ELEMENT_BASEFONT ||
            $context->{'node'}{'id'} == $ELEMENT_BGSOUND  ||
            $context->{'node'}{'id'} == $ELEMENT_LINK     ||
            $context->{'node'}{'id'} == $ELEMENT_META     ||
            $context->{'node'}{'id'} == $ELEMENT_NOFRAMES ||
            $context->{'node'}{'id'} == $ELEMENT_SCRIPT   ||
            $context->{'node'}{'id'} == $ELEMENT_STYLE    ||
            $context->{'node'}{'id'} == $ELEMENT_TEMPLATE ||
            $context->{'node'}{'id'} == $ELEMENT_TITLE) {
            soe_push($context, $context->{'document'}{'head'});
            parser_state_in_head($context);
            soe_remove($context, $context->{'document'}{'head'});
            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_HEAD) {
            return;
        }

    } elsif ($context->{'node'}{'type'} == $NODE_TYPE_END_TAG) {

        if ($context->{'node'}{'id'} == $ELEMENT_TEMPLATE) {
            parser_state_in_head($context);
            return;
        }

        if ($context->{'node'}{'id'} != $ELEMENT_BODY &&
            $context->{'node'}{'id'} != $ELEMENT_HTML &&
            $context->{'node'}{'id'} != $ELEMENT_BR) {
            return;
        }
    }

    $element = node_create_element(0, $ELEMENT_BODY, '', 0);
    $context->{'document'}{'body'} = $element;
    
    node_insert($context, $context->{'soe'}, $element);
    soe_push($context, $element);

    $context->{'document'}{'body'} = $element;
    $context->{'parserstate'} = \&parser_state_in_body;
    $context->{'nodeready'}   = $TRUE;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# https://html.spec.whatwg.org/multipage/syntax.html#parsing-main-inbody
# https://www.w3.org/TR/html/syntax.html#the-in-body-insertion-mode
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub parser_state_in_body
{
    my ($context) = @_;
    my ($element);

    if ($context->{'node'}{'type'} == $NODE_TYPE_EOF) {

        if (@{$context->{'sti'}}) {
            parser_state_in_template($context);
        } else {
            $context->{'parserstate'} = $NULL;
        }

        return;
    }

    if ($context->{'node'}{'type'} == $NODE_TYPE_DOCUMENT_TYPE) {
        return;
    }

    if ($context->{'node'}{'type'} == $NODE_TYPE_TEXT) {
        afe_reconstruct($context);

        node_insert($context, $context->{'soe'}, $context->{'node'});

        if (!($context->{'node'}{'flags'} & $NODE_FLAG_WHITESPACE)) {
            $context->{'flags'} &= ~$PARSER_FLAG_FRAMESET_OK;
        }

        return;
    }

    if ($context->{'node'}{'type'} == $NODE_TYPE_COMMENT) {
        node_insert($context, $context->{'soe'}, $context->{'node'});
        return;
    }

    if ($context->{'node'}{'type'} == $NODE_TYPE_START_TAG) {

        if ($context->{'node'}{'id'} == $ELEMENT_HTML) {

            if (!soe_search_id($context, $ELEMENT_TEMPLATE)) {
                element_merge_attributes($context->{'document'}{'html'}, $context->{'node'});
            }

            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_BASE     ||
            $context->{'node'}{'id'} == $ELEMENT_BASEFONT ||
            $context->{'node'}{'id'} == $ELEMENT_BGSOUND  ||
            $context->{'node'}{'id'} == $ELEMENT_LINK     ||
            $context->{'node'}{'id'} == $ELEMENT_META     ||
            $context->{'node'}{'id'} == $ELEMENT_NOFRAMES ||
            $context->{'node'}{'id'} == $ELEMENT_SCRIPT   ||
            $context->{'node'}{'id'} == $ELEMENT_STYLE    ||
            $context->{'node'}{'id'} == $ELEMENT_TEMPLATE ||
            $context->{'node'}{'id'} == $ELEMENT_TITLE) {
            parser_state_in_head($context);
            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_BODY) {
            
            if ($context->{'document'}{'body'} && !soe_search_id($context, $ELEMENT_TEMPLATE)) {
                element_merge_attributes($context->{'document'}{'body'}, $context->{'node'});
                
                $context->{'flags'} &= ~$PARSER_FLAG_FRAMESET_OK;
            }

            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_FRAMESET) {

            if ($context->{'document'}{'body'} && ($context->{'flags'} & $PARSER_FLAG_FRAMESET_OK)) {
                soe_pop_until_id($context, $ELEMENT_BODY);
                node_remove($context->{'document'}{'html'}, $context->{'document'}{'body'});
                $context->{'document'}{'body'} = $NULL;

                node_insert($context, $context->{'soe'}, $context->{'node'});
                soe_push($context, $context->{'node'});
                $context->{'parserstate'} = \&parser_state_in_frameset;
            }

            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_ADDRESS    ||
            $context->{'node'}{'id'} == $ELEMENT_ARTICLE    ||
            $context->{'node'}{'id'} == $ELEMENT_ASIDE      ||
            $context->{'node'}{'id'} == $ELEMENT_BLOCKQUOTE ||
            $context->{'node'}{'id'} == $ELEMENT_CENTER     ||
            $context->{'node'}{'id'} == $ELEMENT_DETAILS    ||
            $context->{'node'}{'id'} == $ELEMENT_DIALOG     ||
            $context->{'node'}{'id'} == $ELEMENT_DIR        ||
            $context->{'node'}{'id'} == $ELEMENT_DIV        ||
            $context->{'node'}{'id'} == $ELEMENT_DL         ||
            $context->{'node'}{'id'} == $ELEMENT_FIELDSET   ||
            $context->{'node'}{'id'} == $ELEMENT_FIGCAPTION ||
            $context->{'node'}{'id'} == $ELEMENT_FIGURE     ||
            $context->{'node'}{'id'} == $ELEMENT_FOOTER     ||
            $context->{'node'}{'id'} == $ELEMENT_HEADER     ||
            $context->{'node'}{'id'} == $ELEMENT_HGROUP     ||
            $context->{'node'}{'id'} == $ELEMENT_MAIN       ||
            $context->{'node'}{'id'} == $ELEMENT_NAV        ||
            $context->{'node'}{'id'} == $ELEMENT_OL         ||
            $context->{'node'}{'id'} == $ELEMENT_P          ||
            $context->{'node'}{'id'} == $ELEMENT_SECTION    ||
            $context->{'node'}{'id'} == $ELEMENT_SUMMARY    ||
            $context->{'node'}{'id'} == $ELEMENT_UL) {

            if (soe_search_id_until_bitset($context, $scopebitset3, $ELEMENT_P)) {
                soe_pop_until_id($context, $ELEMENT_P);
            }

            node_insert($context, $context->{'soe'}, $context->{'node'});
            soe_push($context, $context->{'node'});
            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_MENU) {

            if (soe_search_id_until_bitset($context, $scopebitset3, $ELEMENT_P)) {
                soe_pop_until_id($context, $ELEMENT_P);
            }

            if ($context->{'soe'}{'id'} == $ELEMENT_MENUITEM) {
                soe_pop($context);
            }

            node_insert($context, $context->{'soe'}, $context->{'node'});
            soe_push($context, $context->{'node'});
            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_H1 ||
            $context->{'node'}{'id'} == $ELEMENT_H2 ||
            $context->{'node'}{'id'} == $ELEMENT_H3 ||
            $context->{'node'}{'id'} == $ELEMENT_H4 ||
            $context->{'node'}{'id'} == $ELEMENT_H5 ||
            $context->{'node'}{'id'} == $ELEMENT_H6) {

            if (soe_search_id_until_bitset($context, $scopebitset3, $ELEMENT_P)) {
                soe_pop_until_id($context, $ELEMENT_P);
            }

            if ($context->{'soe'}{'id'} == $ELEMENT_H1 ||
                $context->{'soe'}{'id'} == $ELEMENT_H2 ||
                $context->{'soe'}{'id'} == $ELEMENT_H3 ||
                $context->{'soe'}{'id'} == $ELEMENT_H4 ||
                $context->{'soe'}{'id'} == $ELEMENT_H5 ||
                $context->{'soe'}{'id'} == $ELEMENT_H6) {
                soe_pop($context);
            }

            node_insert($context, $context->{'soe'}, $context->{'node'});
            soe_push($context, $context->{'node'});
            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_PRE ||
            $context->{'node'}{'id'} == $ELEMENT_LISTING) {

            if (soe_search_id_until_bitset($context, $scopebitset3, $ELEMENT_P)) {
                soe_pop_until_id($context, $ELEMENT_P);
            }

            node_insert($context, $context->{'soe'}, $context->{'node'});
            soe_push($context, $context->{'node'});

            $context->{'flags'} &= ~$PARSER_FLAG_FRAMESET_OK;
            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_FORM) {

            if (soe_search_id($context, $ELEMENT_TEMPLATE) || !$context->{'form'}) {

                if (soe_search_id_until_bitset($context, $scopebitset3, $ELEMENT_P)) {
                    soe_pop_until_id($context, $ELEMENT_P);
                }

                node_insert($context, $context->{'soe'}, $context->{'node'});
                soe_push($context, $context->{'node'});
                # Есть <TEMPLATE>.
                if (!$context->{'form'}) {
                    $context->{'form'} = $context->{'node'};
                }
            }

            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_LI) {
            $element = $context->{'soe'};

            while ($element) {

                if ($element->{'id'} == $ELEMENT_LI) {
                    soe_pop_until_id($context, $ELEMENT_LI);
                    last;
                }

                if (bitset_test($specialbitset2, $element->{'id'})) {
                    last;
                }

                $element = $element->{'soeprevious'};
            }

            if (soe_search_id_until_bitset($context, $scopebitset3, $ELEMENT_P)) {
                soe_pop_until_id($context, $ELEMENT_P);
            }

            node_insert($context, $context->{'soe'}, $context->{'node'});
            soe_push($context, $context->{'node'});

            $context->{'flags'} &= ~$PARSER_FLAG_FRAMESET_OK;
            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_DD ||
            $context->{'node'}{'id'} == $ELEMENT_DT) {
            $element = $context->{'soe'};

            while ($element) {

                if ($element->{'id'} == $ELEMENT_DD) {
                    soe_pop_until_id($context, $ELEMENT_DD);
                    last;
                }

                if ($element->{'id'} == $ELEMENT_DT) {
                    soe_pop_until_id($context, $ELEMENT_DT);
                    last;
                }

                if (bitset_test($specialbitset2, $element->{'id'})) {
                    last;
                }

                $element = $element->{'soeprevious'};
            }

            if (soe_search_id_until_bitset($context, $scopebitset3, $ELEMENT_P)) {
                soe_pop_until_id($context, $ELEMENT_P);
            }

            node_insert($context, $context->{'soe'}, $context->{'node'});
            soe_push($context, $context->{'node'});

            $context->{'flags'} &= ~$PARSER_FLAG_FRAMESET_OK;
            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_PLAINTEXT) {

            if (soe_search_id_until_bitset($context, $scopebitset3, $ELEMENT_P)) {
                soe_pop_until_id($context, $ELEMENT_P);
            }

            node_insert($context, $context->{'soe'}, $context->{'node'});
            element_append_rawdata($context, $context->{'node'});
            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_BUTTON) {

            if (soe_search_id_until_bitset($context, $scopebitset1, $ELEMENT_BUTTON)) {
                soe_pop_until_id($context, $ELEMENT_BUTTON);
            }

            afe_reconstruct($context);

            node_insert($context, $context->{'soe'}, $context->{'node'});
            soe_push($context, $context->{'node'});

            $context->{'flags'} &= ~$PARSER_FLAG_FRAMESET_OK;
            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_A) {
            $element = afe_search_id($context, $ELEMENT_A);

            if ($element && aaa_process($context, $ELEMENT_A) && afe_contain($context, $element)) {
                # Если AAA не удалил элемент.
                afe_remove($context, $element);
                soe_remove($context, $element);
            }

            afe_reconstruct($context);

            node_insert($context, $context->{'soe'}, $context->{'node'});

            soe_push($context, $context->{'node'});
            afe_push($context, $context->{'node'});
            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_B      ||
            $context->{'node'}{'id'} == $ELEMENT_BIG    ||
            $context->{'node'}{'id'} == $ELEMENT_CODE   ||
            $context->{'node'}{'id'} == $ELEMENT_EM     ||
            $context->{'node'}{'id'} == $ELEMENT_FONT   ||
            $context->{'node'}{'id'} == $ELEMENT_I      ||
            $context->{'node'}{'id'} == $ELEMENT_S      ||
            $context->{'node'}{'id'} == $ELEMENT_SMALL  ||
            $context->{'node'}{'id'} == $ELEMENT_STRIKE ||
            $context->{'node'}{'id'} == $ELEMENT_STRONG ||
            $context->{'node'}{'id'} == $ELEMENT_TT     ||
            $context->{'node'}{'id'} == $ELEMENT_U) {
            afe_reconstruct($context);

            node_insert($context, $context->{'soe'}, $context->{'node'});

            soe_push($context, $context->{'node'});
            afe_push($context, $context->{'node'});

            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_NOBR) {
            afe_reconstruct($context);

            if (soe_search_id_until_bitset($context, $scopebitset1, $ELEMENT_NOBR)) {
                aaa_process($context, $ELEMENT_NOBR);
                afe_reconstruct($context);
            }

            node_insert($context, $context->{'soe'}, $context->{'node'});

            soe_push($context, $context->{'node'});
            afe_push($context, $context->{'node'});
            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_APPLET  ||
            $context->{'node'}{'id'} == $ELEMENT_MARQUEE ||
            $context->{'node'}{'id'} == $ELEMENT_OBJECT) {
            afe_reconstruct($context);

            node_insert($context, $context->{'soe'}, $context->{'node'});
            soe_push($context, $context->{'node'});
            afe_insert_marker($context);

            $context->{'flags'} &= ~$PARSER_FLAG_FRAMESET_OK;
            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_TABLE) {

            if (!($context->{'flags'} & $PARSER_FLAG_QUIRKS_MODE_QUIRKS) &&
                soe_search_id_until_bitset($context, $scopebitset3, $ELEMENT_P)) {
                soe_pop_until_id($context, $ELEMENT_P);
            }

            node_insert($context, $context->{'soe'}, $context->{'node'});

            soe_push($context, $context->{'node'});

            $context->{'flags'}       &= ~$PARSER_FLAG_FRAMESET_OK;
            $context->{'parserstate'}  = \&parser_state_in_table;
            return;
        }
        # VOID
        if ($context->{'node'}{'id'} == $ELEMENT_AREA   ||
            $context->{'node'}{'id'} == $ELEMENT_BR     ||
            $context->{'node'}{'id'} == $ELEMENT_EMBED  ||
            $context->{'node'}{'id'} == $ELEMENT_IMG    ||
            $context->{'node'}{'id'} == $ELEMENT_KEYGEN ||
            $context->{'node'}{'id'} == $ELEMENT_WBR) {
            afe_reconstruct($context);

            node_insert($context, $context->{'soe'}, $context->{'node'});
            
            $context->{'flags'} &= ~$PARSER_FLAG_FRAMESET_OK;
            return;
        }
        # VOID
        if ($context->{'node'}{'id'} == $ELEMENT_INPUT) {
            afe_reconstruct($context);

            node_insert($context, $context->{'soe'}, $context->{'node'});

            if (!attribute_contain($context->{'node'}, 'type', 'hidden')) {
                $context->{'flags'} &= ~$PARSER_FLAG_FRAMESET_OK;
            }

            return;
        }
        # VOID
        if ($context->{'node'}{'id'} == $ELEMENT_PARAM  ||
            $context->{'node'}{'id'} == $ELEMENT_SOURCE ||
            $context->{'node'}{'id'} == $ELEMENT_TRACK) {
            node_insert($context, $context->{'soe'}, $context->{'node'});
            return;
        }
        # VOID
        if ($context->{'node'}{'id'} == $ELEMENT_HR) {

            if (soe_search_id_until_bitset($context, $scopebitset3, $ELEMENT_P)) {
                soe_pop_until_id($context, $ELEMENT_P);
            }

            if ($context->{'soe'}{'id'} == $ELEMENT_MENUITEM) {
                soe_pop($context);
            }

            node_insert($context, $context->{'soe'}, $context->{'node'});

            $context->{'flags'} &= ~$PARSER_FLAG_FRAMESET_OK;
            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_IMAGE) {
            $context->{'node'}{'id'} = $ELEMENT_IMG;
            afe_reconstruct($context);

            node_insert($context, $context->{'soe'}, $context->{'node'});

            $context->{'flags'} &= ~$PARSER_FLAG_FRAMESET_OK;
            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_TEXTAREA) {
            node_insert($context, $context->{'soe'}, $context->{'node'});
            element_append_rawdata($context, $context->{'node'});

            $context->{'flags'} &= ~$PARSER_FLAG_FRAMESET_OK;
            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_XMP) {

            if (soe_search_id_until_bitset($context, $scopebitset3, $ELEMENT_P)) {
                soe_pop_until_id($context, $ELEMENT_P);
            }

            afe_reconstruct($context);

            node_insert($context, $context->{'soe'}, $context->{'node'});
            element_append_rawdata($context, $context->{'node'});

            $context->{'flags'} &= ~$PARSER_FLAG_FRAMESET_OK;
            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_IFRAME) {
            node_insert($context, $context->{'soe'}, $context->{'node'});
            element_append_rawdata($context, $context->{'node'});

            $context->{'flags'} &= ~$PARSER_FLAG_FRAMESET_OK;
            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_NOEMBED  ||
           ($context->{'node'}{'id'} == $ELEMENT_NOSCRIPT &&
            $context->{'jscontext'}  && $context->{'jscallback'})) {
            node_insert($context, $context->{'soe'}, $context->{'node'});
            element_append_rawdata($context, $context->{'node'});
            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_SELECT) {
            afe_reconstruct($context);
            node_insert($context, $context->{'soe'}, $context->{'node'});
            soe_push($context, $context->{'node'});

            $context->{'flags'} &= ~$PARSER_FLAG_FRAMESET_OK;

            if ($context->{'parserstate'} == \&parser_state_in_table      ||
                $context->{'parserstate'} == \&parser_state_in_caption    ||
                $context->{'parserstate'} == \&parser_state_in_table_body ||
                $context->{'parserstate'} == \&parser_state_in_row        ||
                $context->{'parserstate'} == \&parser_state_in_cell) {
                $context->{'parserstate'}  = \&parser_state_in_select_in_table;
            } else {
                $context->{'parserstate'} = \&parser_state_in_select;
            }

            return
        }

        if ($context->{'node'}{'id'} == $ELEMENT_OPTGROUP ||
            $context->{'node'}{'id'} == $ELEMENT_OPTION) {

            if ($context->{'soe'}{'id'} == $ELEMENT_OPTION) {
                soe_pop($context);
            }

            afe_reconstruct($context);
            node_insert($context, $context->{'soe'}, $context->{'node'});
            soe_push($context, $context->{'node'});
            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_MENUITEM) {

            if ($context->{'soe'}{'id'} == $ELEMENT_MENUITEM) {
                soe_pop($context);
            }

            afe_reconstruct($context);
            node_insert($context, $context->{'soe'}, $context->{'node'});
            soe_push($context, $context->{'node'});
            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_RB ||
            $context->{'node'}{'id'} == $ELEMENT_RTC) {

            if (soe_search_id_until_bitset($context, $scopebitset1, $ELEMENT_RUBY)) {
                soe_pop_unless_bitset($context, $impliedendbitset1);
            }

            node_insert($context, $context->{'soe'}, $context->{'node'});
            soe_push($context, $context->{'node'});
            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_RP ||
            $context->{'node'}{'id'} == $ELEMENT_RT) {

            if (soe_search_id_until_bitset($context, $scopebitset1, $ELEMENT_RUBY)) {
                soe_pop_unless_bitset($context, $impliedendbitset2);
            }

            node_insert($context, $context->{'soe'}, $context->{'node'});
            soe_push($context, $context->{'node'});
            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_MATH ||
            $context->{'node'}{'id'} == $ELEMENT_SVG) {
            node_insert($context, $context->{'soe'}, $context->{'node'});

            if (!($context->{'node'}{'flags'} & $NODE_FLAG_SELFCLOSING)) {
                element_append_rawdata($context, $context->{'node'});
            }

            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_CAPTION  ||
            $context->{'node'}{'id'} == $ELEMENT_COL      ||
            $context->{'node'}{'id'} == $ELEMENT_COLGROUP ||
            $context->{'node'}{'id'} == $ELEMENT_FRAME    ||
            $context->{'node'}{'id'} == $ELEMENT_HEAD     ||
            $context->{'node'}{'id'} == $ELEMENT_TBODY    ||
            $context->{'node'}{'id'} == $ELEMENT_TD       ||
            $context->{'node'}{'id'} == $ELEMENT_TFOOT    ||
            $context->{'node'}{'id'} == $ELEMENT_TH       ||
            $context->{'node'}{'id'} == $ELEMENT_THEAD    ||
            $context->{'node'}{'id'} == $ELEMENT_TR) {
            return;
        }

        afe_reconstruct($context);
        node_insert($context, $context->{'soe'}, $context->{'node'});
        soe_push($context, $context->{'node'});

    } elsif ($context->{'node'}{'type'} == $NODE_TYPE_END_TAG) {

        if ($context->{'node'}{'id'} == $ELEMENT_TEMPLATE) {
            parser_state_in_head($context);
            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_BODY) {

            if (soe_search_id_until_bitset($context, $scopebitset1, $ELEMENT_BODY)) {
                $context->{'parserstate'} = \&parser_state_after_body;
            }

            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_HTML) {

            if (soe_search_id_until_bitset($context, $scopebitset1, $ELEMENT_BODY)) {
                $context->{'parserstate'} = \&parser_state_after_body;
                $context->{'nodeready'}   = $TRUE;
            }

            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_ADDRESS    ||
            $context->{'node'}{'id'} == $ELEMENT_ARTICLE    ||
            $context->{'node'}{'id'} == $ELEMENT_ASIDE      ||
            $context->{'node'}{'id'} == $ELEMENT_BLOCKQUOTE ||
            $context->{'node'}{'id'} == $ELEMENT_BUTTON     ||
            $context->{'node'}{'id'} == $ELEMENT_CENTER     ||
            $context->{'node'}{'id'} == $ELEMENT_DETAILS    ||
            $context->{'node'}{'id'} == $ELEMENT_DIALOG     ||
            $context->{'node'}{'id'} == $ELEMENT_DIR        ||
            $context->{'node'}{'id'} == $ELEMENT_DIV        ||
            $context->{'node'}{'id'} == $ELEMENT_DL         ||
            $context->{'node'}{'id'} == $ELEMENT_FIELDSET   ||
            $context->{'node'}{'id'} == $ELEMENT_FIGCAPTION ||
            $context->{'node'}{'id'} == $ELEMENT_FIGURE     ||
            $context->{'node'}{'id'} == $ELEMENT_FOOTER     ||
            $context->{'node'}{'id'} == $ELEMENT_HEADER     ||
            $context->{'node'}{'id'} == $ELEMENT_HGROUP     ||
            $context->{'node'}{'id'} == $ELEMENT_LISTING    ||
            $context->{'node'}{'id'} == $ELEMENT_MAIN       ||
            $context->{'node'}{'id'} == $ELEMENT_MENU       ||
            $context->{'node'}{'id'} == $ELEMENT_NAV        ||
            $context->{'node'}{'id'} == $ELEMENT_OL         ||
            $context->{'node'}{'id'} == $ELEMENT_PRE        ||
            $context->{'node'}{'id'} == $ELEMENT_SECTION    ||
            $context->{'node'}{'id'} == $ELEMENT_SUMMARY    ||
            $context->{'node'}{'id'} == $ELEMENT_UL) {

            if (soe_search_id_until_bitset($context, $scopebitset1, $context->{'node'}{'id'})) {
                soe_pop_until_id($context, $context->{'node'}{'id'});
            }

            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_FORM) {

            if (!soe_search_id($context, $ELEMENT_TEMPLATE)) {

                if ($context->{'form'} &&
                    soe_contain($context, $context->{'form'})) {
                    soe_pop_unless_bitset($context, $impliedendbitset1);
                    soe_remove($context, $context->{'form'});
                }

                $context->{'form'} = $NULL;

            } elsif (soe_search_id_until_bitset($context, $scopebitset1, $ELEMENT_FORM)) {
                soe_pop_until_id($context, $ELEMENT_FORM);
            }

            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_P) {

            if (soe_search_id_until_bitset($context, $scopebitset3, $ELEMENT_P)) {
                soe_pop_until_id($context, $ELEMENT_P);
            } else {
                $element = node_create_element(0, $ELEMENT_P, '', 0);
                node_insert($context, $context->{'soe'}, $element);
            }

            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_LI) {

            if (soe_search_id_until_bitset($context, $scopebitset2, $ELEMENT_LI)) {
                soe_pop_until_id($context, $ELEMENT_LI);
            }

            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_DD ||
            $context->{'node'}{'id'} == $ELEMENT_DT) {

            if (soe_search_id_until_bitset($context, $scopebitset1, $context->{'node'}{'id'})) {
                soe_pop_until_id($context, $context->{'node'}{'id'});
            }

            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_H1 ||
            $context->{'node'}{'id'} == $ELEMENT_H2 ||
            $context->{'node'}{'id'} == $ELEMENT_H3 ||
            $context->{'node'}{'id'} == $ELEMENT_H4 ||
            $context->{'node'}{'id'} == $ELEMENT_H5 ||
            $context->{'node'}{'id'} == $ELEMENT_H6) {

            if (soe_search_bitset_until_bitset($context, $scopebitset1, $groupbitset1)){
                soe_pop_until_bitset($context, $groupbitset5);
            }

            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_A      ||
            $context->{'node'}{'id'} == $ELEMENT_B      ||
            $context->{'node'}{'id'} == $ELEMENT_BIG    ||
            $context->{'node'}{'id'} == $ELEMENT_CODE   ||
            $context->{'node'}{'id'} == $ELEMENT_EM     ||
            $context->{'node'}{'id'} == $ELEMENT_FONT   ||
            $context->{'node'}{'id'} == $ELEMENT_I      ||
            $context->{'node'}{'id'} == $ELEMENT_NOBR   ||
            $context->{'node'}{'id'} == $ELEMENT_S      ||
            $context->{'node'}{'id'} == $ELEMENT_SMALL  ||
            $context->{'node'}{'id'} == $ELEMENT_STRIKE ||
            $context->{'node'}{'id'} == $ELEMENT_STRONG ||
            $context->{'node'}{'id'} == $ELEMENT_TT     ||
            $context->{'node'}{'id'} == $ELEMENT_U) {
            aaa_process($context, $context->{'node'}{'id'});
            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_APPLET  ||
            $context->{'node'}{'id'} == $ELEMENT_MARQUEE ||
            $context->{'node'}{'id'} == $ELEMENT_OBJECT) {

            if (soe_search_id_until_bitset($context, $scopebitset1, $context->{'node'}{'id'})) {
                soe_pop_until_id($context, $context->{'node'}{'id'});
                afe_clear($context);
            }

            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_BR) {
            afe_reconstruct($context);

            $element = node_create_element(0, $ELEMENT_BR, '', 0);
            node_insert($context, $context->{'soe'}, $element);

            $context->{'flags'} &= ~$PARSER_FLAG_FRAMESET_OK;
            return;
        }
        # Любой другой закрывающий тег.
        $element = $context->{'soe'};

        while ($element) {

            if ($element->{'id'} == $context->{'node'}{'id'}) {
                soe_pop_until_id($context, $element->{'id'});
                last;
            }

            if (bitset_test($specialbitset1, $element->{'id'})) {
                last;
            }

            $element = $element->{'soeprevious'};
        }
    # Cюда попадать не должны.
    } else { die "$context->{'node'}{'type'}"; }
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# https://html.spec.whatwg.org/multipage/syntax.html#parsing-main-intable
# https://www.w3.org/TR/html/syntax.html#the-in-table-insertion-mode
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub parser_state_in_table
{
    my ($context) = @_;
    my ($element);

    if ($context->{'node'}{'type'} == $NODE_TYPE_DOCUMENT_TYPE) {
        return;
    }

    if ($context->{'node'}{'type'} == $NODE_TYPE_TEXT) {

        if (!($context->{'node'}{'flags'}  & $NODE_FLAG_WHITESPACE) ||
             ($context->{'soe'}{'id'}     != $ELEMENT_TABLE          &&
              $context->{'soe'}{'id'}     != $ELEMENT_TBODY          &&
              $context->{'soe'}{'id'}     != $ELEMENT_TFOOT          &&
              $context->{'soe'}{'id'}     != $ELEMENT_THEAD          &&
              $context->{'soe'}{'id'}     != $ELEMENT_TR)) {
            $context->{'flags'} &= ~$PARSER_FLAG_FRAMESET_OK;
            $context->{'flags'} |= $PARSER_FLAG_FOSTER_PARENTING;

            afe_reconstruct($context);
        }

        node_insert($context, $context->{'soe'}, $context->{'node'});

        $context->{'flags'} &= ~$PARSER_FLAG_FOSTER_PARENTING;
        return;
    }

    if ($context->{'node'}{'type'} == $NODE_TYPE_COMMENT) {
        node_insert($context, $context->{'soe'}, $context->{'node'});
        return;
    }

    if ($context->{'node'}{'type'} == $NODE_TYPE_START_TAG) {

        if ($context->{'node'}{'id'} == $ELEMENT_CAPTION) {
            soe_pop_unless_bitset($context, $groupbitset6);

            node_insert($context, $context->{'soe'}, $context->{'node'});
            soe_push($context, $context->{'node'});
            afe_insert_marker($context);

            $context->{'parserstate'} = \&parser_state_in_caption;
            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_COLGROUP) {
            soe_pop_unless_bitset($context, $groupbitset6);

            node_insert($context, $context->{'soe'}, $context->{'node'});
            soe_push($context, $context->{'node'});

            $context->{'parserstate'} = \&parser_state_in_column_group;
            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_COL) {
            soe_pop_unless_bitset($context, $groupbitset6);

            $element = node_create_element(0, $ELEMENT_COLGROUP, '', 0);
            node_insert($context, $context->{'soe'}, $element);
            soe_push($context, $element);

            $context->{'parserstate'} = \&parser_state_in_column_group;
            $context->{'nodeready'}   = $TRUE;
            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_TBODY ||
            $context->{'node'}{'id'} == $ELEMENT_TFOOT ||
            $context->{'node'}{'id'} == $ELEMENT_THEAD) {
            soe_pop_unless_bitset($context, $groupbitset6);

            node_insert($context, $context->{'soe'}, $context->{'node'});
            soe_push($context, $context->{'node'});

            $context->{'parserstate'} = \&parser_state_in_table_body;
            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_TD ||
            $context->{'node'}{'id'} == $ELEMENT_TH ||
            $context->{'node'}{'id'} == $ELEMENT_TR) {
            soe_pop_unless_bitset($context, $groupbitset6);

            $element = node_create_element(0, $ELEMENT_TBODY, '', 0);
            node_insert($context, $context->{'soe'}, $element);
            soe_push($context, $element);

            $context->{'parserstate'} = \&parser_state_in_table_body;
            $context->{'nodeready'}   = $TRUE;
            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_TABLE) {

            if (soe_search_id_until_bitset($context, $scopebitset4, $ELEMENT_TABLE)) {
                soe_pop_until_id($context, $ELEMENT_TABLE);
                parser_reset_insertion_mode($context);

                $context->{'nodeready'} = $TRUE;
            }

            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_STYLE  ||
            $context->{'node'}{'id'} == $ELEMENT_SCRIPT ||
            $context->{'node'}{'id'} == $ELEMENT_TEMPLATE) {
            parser_state_in_head($context);
            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_FORM) {

            if (!$context->{'form'} && !soe_search_id($context, $ELEMENT_TEMPLATE)) {
                node_insert($context, $context->{'soe'}, $context->{'node'});
                $context->{'form'} = $context->{'node'};
            }

            return;
        }

        # VOID
        # Возможно проваливание после проверки атрибута.
        if ($context->{'node'}{'id'} == $ELEMENT_INPUT &&
            attribute_contain($context->{'node'}, 'type', 'hidden')) {
            node_insert($context, $context->{'soe'}, $context->{'node'});
            return;
        }

    } elsif ($context->{'node'}{'type'} == $NODE_TYPE_END_TAG) {

        if ($context->{'node'}{'id'} == $ELEMENT_TABLE) {

            if (soe_search_id_until_bitset($context, $scopebitset4, $ELEMENT_TABLE)) {
                soe_pop_until_id($context, $ELEMENT_TABLE);
                parser_reset_insertion_mode($context);
            }

            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_BODY     ||
            $context->{'node'}{'id'} == $ELEMENT_CAPTION  ||
            $context->{'node'}{'id'} == $ELEMENT_COL      ||
            $context->{'node'}{'id'} == $ELEMENT_COLGROUP ||
            $context->{'node'}{'id'} == $ELEMENT_HTML     ||
            $context->{'node'}{'id'} == $ELEMENT_TBODY    ||
            $context->{'node'}{'id'} == $ELEMENT_TD       ||
            $context->{'node'}{'id'} == $ELEMENT_TFOOT    ||
            $context->{'node'}{'id'} == $ELEMENT_TH       ||
            $context->{'node'}{'id'} == $ELEMENT_THEAD    ||
            $context->{'node'}{'id'} == $ELEMENT_TR) {
            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_TEMPLATE) {
            parser_state_in_head($context);
            return;
        }
    }

    $context->{'flags'} |= $PARSER_FLAG_FOSTER_PARENTING;
    parser_state_in_body($context);
    $context->{'flags'} &= ~$PARSER_FLAG_FOSTER_PARENTING;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# https://html.spec.whatwg.org/multipage/syntax.html#parsing-main-incaption
# https://www.w3.org/TR/html/syntax.html#the-in-caption-insertion-mode
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub parser_state_in_caption
{
    my ($context) = @_;

    if ($context->{'node'}{'type'} == $NODE_TYPE_START_TAG) {

        if ($context->{'node'}{'id'} == $ELEMENT_CAPTION  ||
            $context->{'node'}{'id'} == $ELEMENT_COL      ||
            $context->{'node'}{'id'} == $ELEMENT_COLGROUP ||
            $context->{'node'}{'id'} == $ELEMENT_TBODY    ||
            $context->{'node'}{'id'} == $ELEMENT_TD       ||
            $context->{'node'}{'id'} == $ELEMENT_TFOOT    ||
            $context->{'node'}{'id'} == $ELEMENT_TH       ||
            $context->{'node'}{'id'} == $ELEMENT_THEAD    ||
            $context->{'node'}{'id'} == $ELEMENT_TR) {

            if (soe_search_id_until_bitset($context, $scopebitset4, $ELEMENT_CAPTION)) {
                soe_pop_until_id($context, $ELEMENT_CAPTION);
                afe_clear($context);

                $context->{'parserstate'} = \&parser_state_in_table;
                $context->{'nodeready'}   = $TRUE;
            }

            return;
        }

    } elsif ($context->{'node'}{'type'} == $NODE_TYPE_END_TAG) {

        if ($context->{'node'}{'id'} == $ELEMENT_CAPTION) {

            if (soe_search_id_until_bitset($context, $scopebitset4, $ELEMENT_CAPTION)) {
                soe_pop_until_id($context, $ELEMENT_CAPTION);
                afe_clear($context);

                $context->{'parserstate'} = \&parser_state_in_table;
            }

            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_TABLE) {

            if (soe_search_id_until_bitset($context, $scopebitset4, $ELEMENT_CAPTION)) {
                soe_pop_until_id($context, $ELEMENT_CAPTION);
                afe_clear($context);

                $context->{'parserstate'} = \&parser_state_in_table;
                $context->{'nodeready'}   = $TRUE;
            }

            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_BODY     ||
            $context->{'node'}{'id'} == $ELEMENT_COL      ||
            $context->{'node'}{'id'} == $ELEMENT_COLGROUP ||
            $context->{'node'}{'id'} == $ELEMENT_HTML     ||
            $context->{'node'}{'id'} == $ELEMENT_TBODY    ||
            $context->{'node'}{'id'} == $ELEMENT_TD       ||
            $context->{'node'}{'id'} == $ELEMENT_TFOOT    ||
            $context->{'node'}{'id'} == $ELEMENT_TH       ||
            $context->{'node'}{'id'} == $ELEMENT_THEAD    ||
            $context->{'node'}{'id'} == $ELEMENT_TR) {
            return;
        }
    }

    parser_state_in_body($context);
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# https://html.spec.whatwg.org/multipage/syntax.html#parsing-main-incolgroup
# https://www.w3.org/TR/html/syntax.html#the-in-column-group-insertion-mode
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub parser_state_in_column_group
{
    my ($context) = @_;

    if ($context->{'node'}{'type'} == $NODE_TYPE_EOF) {
        parser_state_in_body($context);
        return;
    }

    if ($context->{'node'}{'type'} == $NODE_TYPE_DOCUMENT_TYPE) {
        return;
    }

    if ($context->{'node'}{'type'}  == $NODE_TYPE_COMMENT ||
       ($context->{'node'}{'type'}  == $NODE_TYPE_TEXT    &&
        $context->{'node'}{'flags'}  & $NODE_FLAG_WHITESPACE)) {
        node_insert($context, $context->{'soe'}, $context->{'node'});
        return;
    }

    if ($context->{'node'}{'type'} == $NODE_TYPE_START_TAG) {

        if ($context->{'node'}{'id'} == $ELEMENT_HTML) {
            parser_state_in_body($context);
            return;
        }
        # VOID
        if ($context->{'node'}{'id'} == $ELEMENT_COL) {
            node_insert($context, $context->{'soe'}, $context->{'node'});
            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_TEMPLATE) {
            parser_state_in_head($context);
            return;
        }

    } elsif ($context->{'node'}{'type'} == $NODE_TYPE_END_TAG) {

        if ($context->{'node'}{'id'} == $ELEMENT_COLGROUP) {

            if ($context->{'soe'}{'id'} == $ELEMENT_COLGROUP) {
                soe_pop($context);
                $context->{'parserstate'} = \&parser_state_in_table;
            }

            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_COL) {
            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_TEMPLATE) {
            parser_state_in_head($context);
            return;
        }
    }

    if ($context->{'soe'}{'id'} == $ELEMENT_COLGROUP) {
        soe_pop($context);

        $context->{'parserstate'} = \&parser_state_in_table;
        $context->{'nodeready'}   = $TRUE;
    }
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# https://html.spec.whatwg.org/multipage/syntax.html#parsing-main-intbody
# https://www.w3.org/TR/html/syntax.html#the-in-table-body-insertion-mode
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub parser_state_in_table_body
{
    my ($context) = @_;
    my ($element);

    if ($context->{'node'}{'type'} == $NODE_TYPE_START_TAG) {

        if ($context->{'node'}{'id'} == $ELEMENT_TR) {
            soe_pop_unless_bitset($context, $groupbitset8);

            node_insert($context, $context->{'soe'}, $context->{'node'});
            soe_push($context, $context->{'node'});

            $context->{'parserstate'} = \&parser_state_in_row;
            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_TH ||
            $context->{'node'}{'id'} == $ELEMENT_TD) {
            soe_pop_unless_bitset($context, $groupbitset8);

            $element = node_create_element(0, $ELEMENT_TR, '', 0);
            node_insert($context, $context->{'soe'}, $element);
            soe_push($context, $element);

            $context->{'parserstate'} = \&parser_state_in_row;
            $context->{'nodeready'}   = $TRUE;
            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_CAPTION  ||
            $context->{'node'}{'id'} == $ELEMENT_COL      ||
            $context->{'node'}{'id'} == $ELEMENT_COLGROUP ||
            $context->{'node'}{'id'} == $ELEMENT_TBODY    ||
            $context->{'node'}{'id'} == $ELEMENT_TFOOT    ||
            $context->{'node'}{'id'} == $ELEMENT_THEAD) {

            if (soe_search_bitset_until_bitset($context, $scopebitset4, $groupbitset3)) {
                soe_pop_unless_bitset($context, $groupbitset8);
                soe_pop($context);

                $context->{'parserstate'} = \&parser_state_in_table;
                $context->{'nodeready'}   = $TRUE;
            }

            return;
        }

    } elsif ($context->{'node'}{'type'} == $NODE_TYPE_END_TAG) {

        if ($context->{'node'}{'id'} == $ELEMENT_TBODY ||
            $context->{'node'}{'id'} == $ELEMENT_TFOOT ||
            $context->{'node'}{'id'} == $ELEMENT_THEAD) {

            if (soe_search_id_until_bitset($context, $scopebitset4, $context->{'node'}{'id'})) {
                soe_pop_unless_bitset($context, $groupbitset8);
                soe_pop($context);

                $context->{'parserstate'} = \&parser_state_in_table;
            }

            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_TABLE) {

            if (soe_search_bitset_until_bitset($context, $scopebitset4, $groupbitset3)) {
                soe_pop_unless_bitset($context, $groupbitset8);
                soe_pop($context);

                $context->{'parserstate'} = \&parser_state_in_table;
                $context->{'nodeready'}   = $TRUE;
            }

            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_BODY     ||
            $context->{'node'}{'id'} == $ELEMENT_CAPTION  ||
            $context->{'node'}{'id'} == $ELEMENT_COL      ||
            $context->{'node'}{'id'} == $ELEMENT_COLGROUP ||
            $context->{'node'}{'id'} == $ELEMENT_HTML     ||
            $context->{'node'}{'id'} == $ELEMENT_TD       ||
            $context->{'node'}{'id'} == $ELEMENT_TH       ||
            $context->{'node'}{'id'} == $ELEMENT_TR) {
            return;
        }
    }

    parser_state_in_table($context);
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# https://html.spec.whatwg.org/multipage/syntax.html#parsing-main-intr
# https://www.w3.org/TR/html/syntax.html#the-in-row-insertion-mode
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub parser_state_in_row
{
    my ($context) = @_;

    if ($context->{'node'}{'type'} == $NODE_TYPE_START_TAG) {

        if ($context->{'node'}{'id'} == $ELEMENT_TD ||
            $context->{'node'}{'id'} == $ELEMENT_TH) {
            soe_pop_unless_bitset($context, $groupbitset7);

            node_insert($context, $context->{'soe'}, $context->{'node'});
            soe_push($context, $context->{'node'});
            afe_insert_marker($context);

            $context->{'parserstate'} = \&parser_state_in_cell;
            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_CAPTION  ||
            $context->{'node'}{'id'} == $ELEMENT_COL      ||
            $context->{'node'}{'id'} == $ELEMENT_COLGROUP ||
            $context->{'node'}{'id'} == $ELEMENT_TBODY    ||
            $context->{'node'}{'id'} == $ELEMENT_TFOOT    ||
            $context->{'node'}{'id'} == $ELEMENT_THEAD    ||
            $context->{'node'}{'id'} == $ELEMENT_TR) {

            if (soe_search_id_until_bitset($context, $scopebitset4, $ELEMENT_TR)) {
                soe_pop_unless_bitset($context, $groupbitset7);
                soe_pop($context);

                $context->{'parserstate'} = \&parser_state_in_table_body;
                $context->{'nodeready'}   = $TRUE;
            }

            return;
        }

    } elsif ($context->{'node'}{'type'} == $NODE_TYPE_END_TAG) {

        if ($context->{'node'}{'id'} == $ELEMENT_TR) {

            if (soe_search_id_until_bitset($context, $scopebitset4, $ELEMENT_TR)) {
                soe_pop_unless_bitset($context, $groupbitset7);
                soe_pop($context);
                $context->{'parserstate'} = \&parser_state_in_table_body;
            }

            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_TABLE) {

            if (soe_search_id_until_bitset($context, $scopebitset4, $ELEMENT_TR)) {
                soe_pop_unless_bitset($context, $groupbitset7);
                soe_pop($context);

                $context->{'parserstate'} = \&parser_state_in_table_body;
                $context->{'nodeready'}   = $TRUE;
            }

            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_TBODY ||
            $context->{'node'}{'id'} == $ELEMENT_TFOOT ||
            $context->{'node'}{'id'} == $ELEMENT_THEAD) {

            if (soe_search_bitset_until_bitset($context, $scopebitset4, $groupbitset3)) {
                soe_pop_unless_bitset($context, $groupbitset7);
                soe_pop($context);

                $context->{'parserstate'} = \&parser_state_in_table_body;
                $context->{'nodeready'}   = $TRUE;
            }

            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_BODY     ||
            $context->{'node'}{'id'} == $ELEMENT_CAPTION  ||
            $context->{'node'}{'id'} == $ELEMENT_COL      ||
            $context->{'node'}{'id'} == $ELEMENT_COLGROUP ||
            $context->{'node'}{'id'} == $ELEMENT_HTML     ||
            $context->{'node'}{'id'} == $ELEMENT_TD       ||
            $context->{'node'}{'id'} == $ELEMENT_TH) {
            return;
        }
    }

    parser_state_in_table($context);
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# https://html.spec.whatwg.org/multipage/syntax.html#parsing-main-intd
# https://www.w3.org/TR/html/syntax.html#the-in-cell-insertion-mode
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub parser_state_in_cell
{
    my ($context) = @_;

    if ($context->{'node'}{'type'} == $NODE_TYPE_START_TAG) {

        if ($context->{'node'}{'id'} == $ELEMENT_CAPTION  ||
            $context->{'node'}{'id'} == $ELEMENT_COL      ||
            $context->{'node'}{'id'} == $ELEMENT_COLGROUP ||
            $context->{'node'}{'id'} == $ELEMENT_TBODY    ||
            $context->{'node'}{'id'} == $ELEMENT_TD       ||
            $context->{'node'}{'id'} == $ELEMENT_TFOOT    ||
            $context->{'node'}{'id'} == $ELEMENT_TH       ||
            $context->{'node'}{'id'} == $ELEMENT_THEAD    ||
            $context->{'node'}{'id'} == $ELEMENT_TR) {

            if (soe_search_bitset_until_bitset($context, $scopebitset4, $groupbitset2)) {
                soe_pop_until_bitset($context, $groupbitset4);
                afe_clear($context);

                $context->{'parserstate'} = \&parser_state_in_row;
                $context->{'nodeready'}   = $TRUE;
            }

            return;
        }

    } elsif ($context->{'node'}{'type'} == $NODE_TYPE_END_TAG) {

        if ($context->{'node'}{'id'} == $ELEMENT_TD ||
            $context->{'node'}{'id'} == $ELEMENT_TH) {

            if (soe_search_id_until_bitset($context, $scopebitset4, $context->{'node'}{'id'})) {
                soe_pop_until_id($context, $context->{'node'}{'id'});
                afe_clear($context);

                $context->{'parserstate'} = \&parser_state_in_row;
            }

            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_BODY     ||
            $context->{'node'}{'id'} == $ELEMENT_CAPTION  ||
            $context->{'node'}{'id'} == $ELEMENT_COL      ||
            $context->{'node'}{'id'} == $ELEMENT_COLGROUP ||
            $context->{'node'}{'id'} == $ELEMENT_HTML) {
            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_TABLE ||
            $context->{'node'}{'id'} == $ELEMENT_TBODY ||
            $context->{'node'}{'id'} == $ELEMENT_TFOOT ||
            $context->{'node'}{'id'} == $ELEMENT_THEAD ||
            $context->{'node'}{'id'} == $ELEMENT_TR) {

            if (soe_search_id_until_bitset($context, $scopebitset4, $context->{'node'}{'id'})) {
                soe_pop_until_bitset($context, $groupbitset4);
                afe_clear($context);

                $context->{'parserstate'} = \&parser_state_in_row;
                $context->{'nodeready'}   = $TRUE;
            }

            return;
        }
    }

    parser_state_in_body($context);
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# https://html.spec.whatwg.org/multipage/syntax.html#parsing-main-inselect
# https://www.w3.org/TR/html/syntax.html#the-in-select-insertion-mode
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub parser_state_in_select
{
    my ($context) = @_;

    if ($context->{'node'}{'type'} == $NODE_TYPE_EOF) {
        parser_state_in_body($context);
        return;
    }

    if ($context->{'node'}{'type'} == $NODE_TYPE_DOCUMENT_TYPE) {
        return;
    }

    if ($context->{'node'}{'type'} == $NODE_TYPE_COMMENT ||
        $context->{'node'}{'type'} == $NODE_TYPE_TEXT) {
        node_insert($context, $context->{'soe'}, $context->{'node'});
        return;
    }

    if ($context->{'node'}{'type'} == $NODE_TYPE_START_TAG) {

        if ($context->{'node'}{'id'} == $ELEMENT_HTML) {
            parser_state_in_body($context);
            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_OPTION) {

            if ($context->{'soe'}{'id'} == $ELEMENT_OPTION) {
                soe_pop($context);
            }

            node_insert($context, $context->{'soe'}, $context->{'node'});
            soe_push($context, $context->{'node'});
            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_OPTGROUP) {

            if ($context->{'soe'}{'id'} == $ELEMENT_OPTION) {
                soe_pop($context);
            }

            if ($context->{'soe'}{'id'} == $ELEMENT_OPTGROUP) {
                soe_pop($context);
            }

            node_insert($context, $context->{'soe'}, $context->{'node'});
            soe_push($context, $context->{'node'});
            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_SELECT) {

            if (soe_search_id_until_bitset($context, $scopebitset5, $ELEMENT_SELECT)) {
                soe_pop_until_id($context, $ELEMENT_SELECT);
                parser_reset_insertion_mode($context);
            }

            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_INPUT  ||
            $context->{'node'}{'id'} == $ELEMENT_KEYGEN ||
            $context->{'node'}{'id'} == $ELEMENT_TEXTAREA) {

            if (soe_search_id_until_bitset($context, $scopebitset5, $ELEMENT_SELECT)) {
                soe_pop_until_id($context, $ELEMENT_SELECT);
                parser_reset_insertion_mode($context);

                $context->{'nodeready'} = $TRUE;
            }

            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_SCRIPT ||
            $context->{'node'}{'id'} == $ELEMENT_TEMPLATE) {
            parser_state_in_head($context);
            return;
        }

    } elsif ($context->{'node'}{'type'} == $NODE_TYPE_END_TAG) {

        if ($context->{'node'}{'id'} == $ELEMENT_OPTGROUP) {

            if ($context->{'soe'}{'id'}                    == $ELEMENT_OPTION &&
                $context->{'soe'}{'soeprevious'}{'id'} == $ELEMENT_OPTGROUP) {
                soe_pop($context);
            }

            if ($context->{'soe'}{'id'} == $ELEMENT_OPTGROUP) {
                soe_pop($context);
            }

            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_OPTION) {

            if ($context->{'soe'}{'id'} == $ELEMENT_OPTION) {
                soe_pop($context);
            }

            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_SELECT) {

            if (soe_search_id_until_bitset($context, $scopebitset5, $ELEMENT_SELECT)) {
                soe_pop_until_id($context, $ELEMENT_SELECT);
                parser_reset_insertion_mode($context);
            }

            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_TEMPLATE) {
            parser_state_in_head($context);
            return;
        }
    }
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# https://html.spec.whatwg.org/multipage/syntax.html#parsing-main-inselectintable
# https://www.w3.org/TR/html/syntax.html#the-in-select-in-table-insertion-mode
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub parser_state_in_select_in_table
{
    my ($context) = @_;

    if ($context->{'node'}{'type'} == $NODE_TYPE_START_TAG) {

        if ($context->{'node'}{'id'} == $ELEMENT_CAPTION ||
            $context->{'node'}{'id'} == $ELEMENT_TABLE   ||
            $context->{'node'}{'id'} == $ELEMENT_TBODY   ||
            $context->{'node'}{'id'} == $ELEMENT_TFOOT   ||
            $context->{'node'}{'id'} == $ELEMENT_THEAD   ||
            $context->{'node'}{'id'} == $ELEMENT_TR      ||
            $context->{'node'}{'id'} == $ELEMENT_TD      ||
            $context->{'node'}{'id'} == $ELEMENT_TH) {
            soe_pop_until_id($context, $ELEMENT_SELECT);
            parser_reset_insertion_mode($context);

            $context->{'nodeready'} = $TRUE;
            return;
        }

    } elsif ($context->{'node'}{'type'} == $NODE_TYPE_END_TAG) {

        if ($context->{'node'}{'id'} == $ELEMENT_CAPTION ||
            $context->{'node'}{'id'} == $ELEMENT_TABLE   ||
            $context->{'node'}{'id'} == $ELEMENT_TBODY   ||
            $context->{'node'}{'id'} == $ELEMENT_TFOOT   ||
            $context->{'node'}{'id'} == $ELEMENT_THEAD   ||
            $context->{'node'}{'id'} == $ELEMENT_TR      ||
            $context->{'node'}{'id'} == $ELEMENT_TD      ||
            $context->{'node'}{'id'} == $ELEMENT_TH) {

            if (soe_search_id_until_bitset($context, $scopebitset4, $context->{'node'}{'id'})) {
                soe_pop_until_id($context, $ELEMENT_SELECT);
                parser_reset_insertion_mode($context);

                $context->{'nodeready'} = $TRUE;
            }

            return;
        }
    }

    parser_state_in_select($context);
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# https://html.spec.whatwg.org/multipage/syntax.html#parsing-main-intemplate
# https://www.w3.org/TR/html/syntax.html#the-in-template-insertion-mode
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub parser_state_in_template
{
    my ($context) = @_;

    if ($context->{'node'}{'type'} == $NODE_TYPE_EOF) {

        if (soe_search_id($context, $ELEMENT_TEMPLATE)) {
            soe_pop_until_id($context, $ELEMENT_TEMPLATE);
            afe_clear($context);
            sti_pop($context);
            parser_reset_insertion_mode($context);
        } else {
            $context->{'parserstate'} = $NULL;
        }

        return;
    }

    if ($context->{'node'}{'type'} == $NODE_TYPE_TEXT    ||
        $context->{'node'}{'type'} == $NODE_TYPE_COMMENT ||
        $context->{'node'}{'type'} == $NODE_TYPE_DOCUMENT_TYPE) {
        parser_state_in_body($context);
        return;
    }

    if ($context->{'node'}{'type'} == $NODE_TYPE_START_TAG) {

        if ($context->{'node'}{'id'} == $ELEMENT_BASE     ||
            $context->{'node'}{'id'} == $ELEMENT_BASEFONT ||
            $context->{'node'}{'id'} == $ELEMENT_BGSOUND  ||
            $context->{'node'}{'id'} == $ELEMENT_LINK     ||
            $context->{'node'}{'id'} == $ELEMENT_META     ||
            $context->{'node'}{'id'} == $ELEMENT_NOFRAMES ||
            $context->{'node'}{'id'} == $ELEMENT_SCRIPT   ||
            $context->{'node'}{'id'} == $ELEMENT_STYLE    ||
            $context->{'node'}{'id'} == $ELEMENT_TEMPLATE ||
            $context->{'node'}{'id'} == $ELEMENT_TITLE) {
            parser_state_in_head($context);
            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_CAPTION  ||
            $context->{'node'}{'id'} == $ELEMENT_COLGROUP ||
            $context->{'node'}{'id'} == $ELEMENT_TBODY    ||
            $context->{'node'}{'id'} == $ELEMENT_TFOOT    ||
            $context->{'node'}{'id'} == $ELEMENT_THEAD) {
            sti_pop($context);
            sti_push($context, \&parser_state_in_table);

            $context->{'parserstate'} = \&parser_state_in_table;
            $context->{'nodeready'}   = $TRUE;
            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_COL) {
            sti_pop($context);
            sti_push($context, \&parser_state_in_column_group);

            $context->{'parserstate'} = \&parser_state_in_column_group;
            $context->{'nodeready'}   = $TRUE;
            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_TR) {
            sti_pop($context);
            sti_push($context, \&parser_state_in_table_body);

            $context->{'parserstate'} = \&parser_state_in_table_body;
            $context->{'nodeready'}   = $TRUE;
            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_TD ||
            $context->{'node'}{'id'} == $ELEMENT_TH) {
            sti_pop($context);
            sti_push($context, \&parser_state_in_row);

            $context->{'parserstate'} = \&parser_state_in_row;
            $context->{'nodeready'}   = $TRUE;
            return;
        }

        sti_pop($context);
        sti_push($context, \&parser_state_in_body);

        $context->{'parserstate'} = \&parser_state_in_body;
        $context->{'nodeready'}   = $TRUE;

    } elsif ($context->{'node'}{'type'} == $NODE_TYPE_END_TAG) {

        if ($context->{'node'}{'id'} == $ELEMENT_TEMPLATE) {
            parser_state_in_head($context);
            return;
        }
    }
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# https://html.spec.whatwg.org/multipage/syntax.html#parsing-main-afterbody
# https://www.w3.org/TR/html/syntax.html#the-after-body-insertion-mode
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub parser_state_after_body
{
    my ($context) = @_;

    if ($context->{'node'}{'type'} == $NODE_TYPE_EOF) {
        $context->{'parserstate'} = $NULL;
        return;
    }

    if ($context->{'node'}{'type'} == $NODE_TYPE_DOCUMENT_TYPE) {
        return;
    }

    if ($context->{'node'}{'type'}  == $NODE_TYPE_TEXT &&
        $context->{'node'}{'flags'}  & $NODE_FLAG_WHITESPACE) {
        parser_state_in_body($context);
        return;
    }

    if ($context->{'node'}{'type'} == $NODE_TYPE_COMMENT) {
        node_append($context->{'document'}{'html'}, $context->{'node'});
        return;
    }

    if ($context->{'node'}{'type'} == $NODE_TYPE_START_TAG) {

        if ($context->{'node'}{'id'} == $ELEMENT_HTML) {
            parser_state_in_body($context);
            return;
        }

    } elsif ($context->{'node'}{'type'} == $NODE_TYPE_END_TAG) {

        if ($context->{'node'}{'id'} == $ELEMENT_HTML) {

            if (!$context->{'context'}) {
                $context->{'parserstate'} = \&parser_state_after_after_body;
            }

            return;
        }
    }

    $context->{'parserstate'} = \&parser_state_in_body;
    $context->{'nodeready'}   = $TRUE;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# https://html.spec.whatwg.org/multipage/syntax.html#parsing-main-inframeset
# https://www.w3.org/TR/html/syntax.html#the-in-frameset-insertion-mode
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub parser_state_in_frameset
{
    my ($context) = @_;

    if ($context->{'node'}{'type'} == $NODE_TYPE_EOF) {
        $context->{'parserstate'} = $NULL;
        return;
    }

    if ($context->{'node'}{'type'} == $NODE_TYPE_DOCUMENT_TYPE) {
        return;
    }

    if ($context->{'node'}{'type'}  == $NODE_TYPE_COMMENT ||
       ($context->{'node'}{'type'}  == $NODE_TYPE_TEXT    &&
        $context->{'node'}{'flags'}  & $NODE_FLAG_WHITESPACE)){
        node_insert($context, $context->{'soe'}, $context->{'node'});
        return;
    }

    if ($context->{'node'}{'type'} == $NODE_TYPE_START_TAG) {

        if ($context->{'node'}{'id'} == $ELEMENT_HTML) {
            parser_state_in_body($context);
            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_FRAMESET) {
            node_insert($context, $context->{'soe'}, $context->{'node'});
            soe_push($context, $context->{'node'});
            return;
        }
        # VOID
        if ($context->{'node'}{'id'} == $ELEMENT_FRAME) {
            node_insert($context, $context->{'soe'}, $context->{'node'});
            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_NOFRAMES) {
            parser_state_in_head($context);
            return;
        }

    } elsif ($context->{'node'}{'type'} == $NODE_TYPE_END_TAG) {

        if ($context->{'node'}{'id'} == $ELEMENT_FRAMESET) {

            if ($context->{'soe'}{'id'} != $ELEMENT_HTML) {
                soe_pop($context);

                if (!$context->{'context'} &&
                    $context->{'soe'}{'id'} != $ELEMENT_FRAMESET) {
                    $context->{'parserstate'} = \&parser_state_after_frameset;
                }
            }

            return;
        }
    }
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# https://html.spec.whatwg.org/multipage/syntax.html#parsing-main-afterframeset
# https://www.w3.org/TR/html/syntax.html#the-after-frameset-insertion-mode
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub parser_state_after_frameset
{
    my ($context) = @_;

    if ($context->{'node'}{'type'} == $NODE_TYPE_EOF) {
        $context->{'parserstate'} = $NULL;
        return;
    }

    if ($context->{'node'}{'type'} == $NODE_TYPE_DOCUMENT_TYPE) {
        return;
    }

    if ($context->{'node'}{'type'}  == $NODE_TYPE_COMMENT ||
       ($context->{'node'}{'type'}  == $NODE_TYPE_TEXT    &&
        $context->{'node'}{'flags'}  & $NODE_FLAG_WHITESPACE)) {
        node_insert($context, $context->{'soe'}, $context->{'node'});
        return;
    }

    if ($context->{'node'}{'type'} == $NODE_TYPE_START_TAG) {

        if ($context->{'node'}{'id'} == $ELEMENT_HTML) {
            parser_state_in_body($context);
            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_NOFRAMES) {
            parser_state_in_head($context);
            return;
        }

    } elsif ($context->{'node'}{'type'} == $NODE_TYPE_END_TAG) {

        if ($context->{'node'}{'id'} == $ELEMENT_HTML) {
            $context->{'parserstate'} = \&parser_state_after_after_frameset;
            return;
        }
    }
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# https://html.spec.whatwg.org/multipage/syntax.html#the-after-after-body-insertion-mode
# https://www.w3.org/TR/html/syntax.html#the-after-after-body-insertion-mode
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub parser_state_after_after_body
{
    my ($context) = @_;

    if ($context->{'node'}{'type'} == $NODE_TYPE_EOF) {
        $context->{'parserstate'} = $NULL;
        return;
    }

    if ($context->{'node'}{'type'} == $NODE_TYPE_COMMENT) {
        node_append($context->{'document'}, $context->{'node'});
        return;
    }

    if ($context->{'node'}{'type'}  == $NODE_TYPE_DOCUMENT_TYPE ||
       ($context->{'node'}{'type'}  == $NODE_TYPE_START_TAG     &&
        $context->{'node'}{'id'}    == $ELEMENT_HTML)           ||
       ($context->{'node'}{'type'}  == $NODE_TYPE_TEXT          &&
        $context->{'node'}{'flags'}  & $NODE_FLAG_WHITESPACE)) {
        parser_state_in_body($context);
        return;
    }

    $context->{'parserstate'} = \&parser_state_in_body;
    $context->{'nodeready'}   = $TRUE;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# https://html.spec.whatwg.org/multipage/syntax.html#the-after-after-frameset-insertion-mode
# https://www.w3.org/TR/html/syntax.html#the-after-after-frameset-insertion-mode
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub parser_state_after_after_frameset
{
    my ($context) = @_;

    if ($context->{'node'}{'type'} == $NODE_TYPE_EOF) {
        $context->{'parserstate'} = $NULL;
        return;
    }

    if ($context->{'node'}{'type'} == $NODE_TYPE_COMMENT) {
        node_append($context->{'document'}, $context->{'node'});
        return;
    }

    if ($context->{'node'}{'type'}  == $NODE_TYPE_DOCUMENT_TYPE ||
       ($context->{'node'}{'type'}  == $NODE_TYPE_TEXT          &&
        $context->{'node'}{'flags'}  & $NODE_FLAG_WHITESPACE)) {
        parser_state_in_body($context);
        return;
    }

    if ($context->{'node'}{'type'} == $NODE_TYPE_START_TAG) {

        if ($context->{'node'}{'id'} == $ELEMENT_HTML) {
            parser_state_in_body($context);
            return;
        }

        if ($context->{'node'}{'id'} == $ELEMENT_NOFRAMES) {
            parser_state_in_head($context);
            return;
        }
    }
}

1;