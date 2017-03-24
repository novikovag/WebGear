#===============================================================================
#       Сканер
#===============================================================================

package WebGear::HTML::Scanner;
use strict;

use Exporter qw(import);
our @EXPORT = qw(
    scanner_state_text
    scanner_state_rawdata
    scanner_state_plaintext
    scanner_state_script
    scanner_state_foreigndata
);

use WebGear::HTML::Filter;
use WebGear::HTML::Constants;
use WebGear::HTML::Tries;
use WebGear::HTML::DOM;
use WebGear::HTML::Utilities;

sub scanner_state_text
{
    my ($context) = @_;
    my ($datastartindex, $charrefstartindex, $spacecount, $charrefutf8, $data, $datalength);

    $datastartindex = $context->{'inbuffer'}{'index'};
    $data           = '';
    $datalength     = 0;
    $spacecount     = 0;

    while (n(0) && char_is_space(c(0))) {
        $spacecount++;
        $context->{'inbuffer'}{'index'}++;
    }

    while (n(0)) {

        if (c(0) == 0x3c && n(1)) { # '<'

            if (char_is_alpha(c(1))) {
                $context->{'scannerstate'} = \&scanner_state_element;
                last;
            }

            if (c(1) == 0x2f && n(2)) { # '/'

                if (char_is_alpha(c(2))) {
                    $context->{'scannerstate'} = \&scanner_state_element;
                } else {
                    $context->{'scannerstate'} = \&scanner_state_bogus_comment;
                }

                last;
            }

            if (c(1) == 0x21) { # '!'

                if (n(3) && c(2) == 0x2d && c(3) == 0x2d) { # '-', '-'
                    $context->{'scannerstate'} = \&scanner_state_comment;
                    last;
                }

                if (n(8)) {

                    if (char_to_lower(c(2)) == 0x64 && # 'd'
                        char_to_lower(c(3)) == 0x6f && # 'o'
                        char_to_lower(c(4)) == 0x63 && # 'c'
                        char_to_lower(c(5)) == 0x74 && # 't'
                        char_to_lower(c(6)) == 0x79 && # 'y'
                        char_to_lower(c(7)) == 0x70 && # 'p'
                        char_to_lower(c(8)) == 0x65) { # 'e'
                        $context->{'scannerstate'} = \&scanner_state_documenttype;
                        last;
                    }

                    if (c(2)                == 0x5b && # '['
                        char_to_lower(c(3)) == 0x63 && # 'c'
                        char_to_lower(c(4)) == 0x64 && # 'd'
                        char_to_lower(c(5)) == 0x61 && # 'a'
                        char_to_lower(c(6)) == 0x74 && # 't'
                        char_to_lower(c(7)) == 0x61 && # 'a'
                        c(8)                == 0x5b) { # '['
                        $context->{'scannerstate'} = \&scanner_state_cdata;
                        last;
                    }
                }
                # Проваливаемся при прочих условиях.
                $context->{'scannerstate'} = \&scanner_state_bogus_comment;
                last;
            }

            if (c(1) == 0x3f) { # '?'
                $context->{'scannerstate'} = \&scanner_state_bogus_comment;
                last;
            }

        } elsif (c(0) == 0x26 && n(2)) { # '&'
            $charrefstartindex = $context->{'inbuffer'}{'index'};
            $charrefutf8       = charref_parse($context);

            if ($charrefutf8) {
                # Есть необработанная строка.
                if ($datastartindex < $charrefstartindex) {
                    $datalength += $charrefstartindex - $datastartindex;
                    $data       .= text($datastartindex, $charrefstartindex - $datastartindex);
                }

                $datalength += $charrefutf8->[0];
                $data       .= pack("C$charrefutf8->[0]", @{$charrefutf8->[1]});

                $datastartindex = $context->{'inbuffer'}{'index'};
            }
            # Обработчик ссылки уже увеличил индекс.
            next;
        }

        $context->{'inbuffer'}{'index'}++;
    }
    # Есть необработанная строка.
    if ($datastartindex < $context->{'inbuffer'}{'index'}) {
        $datalength += $context->{'inbuffer'}{'index'} - $datastartindex;
        $data       .= text($datastartindex, $context->{'inbuffer'}{'index'} - $datastartindex);
    }

    if ($datalength) {
        $context->{'node'}      = node_create_textnode($spacecount == $datalength, $data, $datalength);
        $context->{'nodeready'} = $TRUE;
    }
}

sub scanner_state_element
{
    my ($context) = @_;
    my ($isendtag, $namestartindex, $quote, $flags, $id, $name, $namelength);

    if (c(0) == 0x2f) { # '/'
        $context->{'inbuffer'}{'index'}++;
        $isendtag = $TRUE;
    } else {
        $isendtag = $FALSE;
    }

    $flags = 0;
    $namestartindex = $context->{'inbuffer'}{'index'};

    $id = trie_search_case_insensitive($context, \@elementtrienodes, $elementtrieroots[char_to_lower(c(0))]);

    while (1) {
        # Здесь и далее при EOF узел не отправляется.
        if (!n(0)) {
            return;
        }

        if (c(0) == 0x3e) { # '>'
            $context->{'nodeready'} = $TRUE;
        } elsif (char_is_space(c(0))) {
        } elsif (c(0) == 0x2f) { # '/'

            if (n(1) && c(1) == 0x3e) { # '>'
                $context->{'nodeready'} = $TRUE;
                $flags |= $NODE_FLAG_SELFCLOSING;

                $context->{'inbuffer'}{'index'}++;
            }

        } else {
            $id = $UNKNOWN;
            $context->{'inbuffer'}{'index'}++;
            next;
        }

        last;
    }

    $namelength = $context->{'inbuffer'}{'index'} - $namestartindex;
    $name       = uc text($namestartindex, $namelength);

    if ($isendtag) {
        $context->{'node'} = node_create_endtag($flags, $id, $name, $namelength);

        if (!$context->{'nodeready'}) {
            $quote = '';
            # Пропуск возможных атрибутов с учетом кавычек.
            while (1) {
                $context->{'inbuffer'}{'index'}++;

                if (!n(0)) {
                    return;
                }

                if (c(0) == 0x22 || c(0) == 0x27) { # ''', '"'

                    if (!$quote) {
                        $quote = c(0);
                    } elsif ($quote == c(0)) {
                        $quote = '';
                    }

                    next;
                }

                if (c(0) == 0x3e && !$quote) { # '>'
                    $context->{'nodeready'} = $TRUE;
                    last;
                }
            }
        }

    } else {
        $context->{'node'} = node_create_element($flags, $id, $name, $namelength);

        if (!$context->{'nodeready'}) {
           $context->{'scannerstate'} = \&scanner_state_attributes;
           return;
        }
    }

    $context->{'scannerstate'} = \&scanner_state_text;
}

sub scanner_state_attributes
{
    my ($context) = @_;
    my ($isevent, $namestartindex, $valuestartindex, $charrefstartindex, $quote, $charrefutf8, $flags, $id, $name, $namelength, $value, $valuelength);

    $context->{'scannerstate'} = \&scanner_state_text;

    while (1) {
        # Здесь и далее при EOF узел не отправляется.
        if (!n(0)) {
            return;
        }

        if (c(0) == 0x3e) { # '>'
            last;
        }

        if (c(0) == 0x2f) { # '/'
            $context->{'inbuffer'}{'index'}++;

            if (n(0) && c(0) == 0x3e) { # '>'
                $context->{'node'}{'flags'} |= $NODE_FLAG_SELFCLOSING;
                last;
            }
        }

        if (char_is_space(c(0))) {
            $context->{'inbuffer'}{'index'}++;
            next;
        }

        $namestartindex = $context->{'inbuffer'}{'index'};
        # Условие из "Before attribute name state" позволяет имени атрибута начинаться
        # с символа '=': https://html.spec.whatwg.org/multipage/syntax.html#before-attribute-name-state
        if (c(0) == 0x3d) { # '='
            $context->{'inbuffer'}{'index'}++;
            $id = $UNKNOWN;
        # Все имена с префиксом 'on-' считаются событиями, префикс пропускается.
        } elsif (char_to_lower(c(0)) == 0x6f && n(2) && char_to_lower(c(1)) == 0x6e) { # 'on'
            $isevent = $TRUE;
            $namestartindex     += 2;
            $context->{'inbuffer'}{'index'} += 2;
            $id = trie_search_case_insensitive($context, \@eventtrienodes, $eventtrieroots[char_to_lower(c(0))]);
        } else {
            $isevent = $FALSE;
            $id = trie_search_case_insensitive($context, \@atributetrienodes, $atributetrieroots[char_to_lower(c(0))]);
        }

        while (1) {

            if (!n(0)) {
                return;
            }

            if (char_is_space(c(0)) || c(0) == 0x2f || c(0) == 0x3e || c(0) == 0x3d) { # '/', '>', '='
                last;
            }

            $id = $UNKNOWN;
            $context->{'inbuffer'}{'index'}++;
        }

        $namelength  = $context->{'inbuffer'}{'index'} - $namestartindex;

        $value       = '';
        $valuelength = 0;

        while (1) {

            if (!char_is_space(c(0))) {
                last;
            }

            $context->{'inbuffer'}{'index'}++;

            if (!n(0)) {
                return;
            }
        }

        if (c(0) == 0x3d) { # '='

            while (1) {
                $context->{'inbuffer'}{'index'}++;

                if (!n(0)) {
                    return;
                }

                if (!char_is_space(c(0))) {
                    last;
                }
            }

            if (c(0) == 0x22 || c(0) == 0x27) { # '"', '''
                $quote = c(0);
                $context->{'inbuffer'}{'index'}++;
            } else {
                $quote = '';
            }

            $valuestartindex = $context->{'inbuffer'}{'index'};

            while (1) {

                if (!n(0)) {
                    return;
                }

                if ($quote) {

                    if (c(0) == $quote) {
                        last;
                    }
                # Исключая '/' например в <tag attribute=https://www.address.ru>
                } elsif (char_is_space(c(0)) || c(0) == 0x3e || (c(0) == 0x2f && n(1) && c(1) == 0x3e)) { # '>', '/>'
                    last;
                }

                if (c(0) == 0x26 && n(2)) { # '&'
                    $charrefstartindex = $context->{'inbuffer'}{'index'};
                    $charrefutf8       = charref_parse($context);

                    if ($charrefutf8) {

                        if ($valuestartindex < $charrefstartindex ) {
                            $valuelength += $charrefstartindex  - $valuestartindex;
                            $value       .= text($valuestartindex, $charrefstartindex - $valuestartindex);
                        }

                        $valuelength += $charrefutf8->[0];
                        $value       .= pack("C$charrefutf8->[0]", @{$charrefutf8->[1]});

                        $valuestartindex = $context->{'inbuffer'}{'index'};
                    }

                    next;
                }

                $context->{'inbuffer'}{'index'}++;
            }

            if ($context->{'inbuffer'}{'index'} > $valuestartindex) {
                $valuelength += $context->{'inbuffer'}{'index'} - $valuestartindex;
                $value       .= text($valuestartindex, $context->{'inbuffer'}{'index'} - $valuestartindex);
            }

            if ($quote) {
                $context->{'inbuffer'}{'index'}++;
            }
        }

        $name = lc text($namestartindex, $namelength);

        if ($isevent) {

            if (!exists $context->{'node'}{'events'}{$name}) {
                $context->{'node'}{'events'}{$name} = node_create_event($context->{'node'}, $id, $name, $namelength, $value, $valuelength);
            }

        } else {

            if (!exists $context->{'node'}{'attributes'}{$name}) {
                $context->{'node'}{'attributes'}{$name} = node_create_attribute($context->{'node'}, $id, $name, $namelength, $value, $valuelength);
            }
        }
    }

    $context->{'nodeready'} = $TRUE;
}

sub scanner_state_documenttype
{
    my ($context) = @_;
    my ($ispublic, $namestartindex, $dtdtartindex, $dtdid, $quote, $flags, $id, $name, $namelength, $publicid, $public, $publiclength, $systemid, $system, $systemlength);

    $context->{'scannerstate'} = \&scanner_state_text;

    $context->{'inbuffer'}{'index'} += 8;
    $flags               = 0;

    while (1) {
        # Здесь и далее при EOF токен не отправляется.
        if (!n(0)) {
            return;
        }

        if (c(0) == 0x3e) { # '>'
            $flags |= $NODE_FLAG_FORCE_QUIRKS;
            goto L1;
        }

        if (!char_is_space(c(0))) {
            last;
        }

        $context->{'inbuffer'}{'index'}++;
    }

    $namestartindex = $context->{'inbuffer'}{'index'};

    if (n(3) && char_to_lower(c(0)) == 0x68 && # 'h'
                char_to_lower(c(1)) == 0x74 && # 't'
                char_to_lower(c(2)) == 0x6d && # 'm'
                char_to_lower(c(3)) == 0x6c) { # 'l'
        $id = $DOCUMENTTYPE_HTML;
        $context->{'inbuffer'}{'index'} += 4;
    } else {
        $id = $UNKNOWN;
    }

    while (1) {

        if (!n(0)) {
            return;
        }

        if (c(0) == 0x3e || char_is_space(c(0))) { # '>'
            last;
        }

        $id = $UNKNOWN;
        $context->{'inbuffer'}{'index'}++;
    }

    $namelength   = $context->{'inbuffer'}{'index'} - $namestartindex;
    $name         = lc text($namestartindex, $namelength);

    $publicid     = $UNKNOWN;
    $public       = '';
    $publiclength = 0;
    $systemid     = $UNKNOWN;
    $system       = '';
    $systemlength = 0;

    while (1) {

        if (!n(0)) {
            return;
        }

        if (c(0) == 0x3e) { # '>'
            goto L2;
        }

        if (!char_is_space(c(0))) {
            last;
        }

        $context->{'inbuffer'}{'index'}++;
    }

    if (n(5)) {

        if (char_to_lower(c(0)) == 0x70 &&      # 'p'
            char_to_lower(c(1)) == 0x75 &&      # 'u'
            char_to_lower(c(2)) == 0x62 &&      # 'b'
            char_to_lower(c(3)) == 0x6c &&      # 'l'
            char_to_lower(c(4)) == 0x69 &&      # 'i'
            char_to_lower(c(5)) == 0x63) {      # 'c'
            $ispublic = $TRUE;
        } elsif (char_to_lower(c(0)) == 0x73 || # 's'
                 char_to_lower(c(1)) == 0x79 || # 'y'
                 char_to_lower(c(2)) == 0x73 || # 's'
                 char_to_lower(c(3)) == 0x74 || # 't'
                 char_to_lower(c(4)) == 0x65 || # 'e'
                 char_to_lower(c(5)) == 0x6d) { # 'm'
            $ispublic = $FALSE;
        } else {
            goto L1;
        }

        $context->{'inbuffer'}{'index'} += 6;

        while (1) {

            if (!n(0)) {
                return;
            }

            if (!char_is_space(c(0))) {
                last;
            }

            $context->{'inbuffer'}{'index'}++;
        }

        while (1) {

            if (c(0) != 0x22 && c(0) != 0x27) { # '"', '''
                $flags |= $NODE_FLAG_FORCE_QUIRKS;

                if (c(0) == 0x3e) { # '>'
                    goto L2;
                }

                last;
            }

            $quote = c(0);

            $dtdtartindex = ++$context->{'inbuffer'}{'index'};
            $dtdid        = trie_search_case_insensitive($context, \@documenttypetrienodes, $documenttypetrieroots[char_to_lower(c(0))]);

            while (1) {

                if (!n(0)) {
                    return;
                }

                if (c(0) == $quote) {
                    last;
                }

                $context->{'inbuffer'}{'index'}++;
            }

            if ($ispublic) {
                $publicid     = $dtdid;
                $publiclength = $context->{'inbuffer'}{'index'} - $dtdtartindex;
                $public       = text($dtdtartindex, $publiclength);
            } else {
                $systemid     = $dtdid;
                $systemlength = $context->{'inbuffer'}{'index'} - $dtdtartindex;
                $system       = text($dtdtartindex, $systemlength);
            }
            # Пропуск кавычки.
            $context->{'inbuffer'}{'index'}++;

            while (1) {

                if (!n(0)) {
                    return;
                }

                if (c(0) == 0x3e) { # '>'
                    goto L2;
                }

                if (!char_is_space(c(0))) {
                    last;
                }

                $context->{'inbuffer'}{'index'}++;
            }

            if (!$ispublic) {
                last;
            }

            $ispublic = $FALSE;
        }
    }
L1:
    # Bogus DOCTYPE.
    while (1) {

        if (!n(0)) {
            return;
        }

        if (c(0) == 0x3e) { # '>'
            last;
        }

        $context->{'inbuffer'}{'index'}++;
    }
L2:
    $context->{'node'}      = node_create_documenttype($flags, $id, $name, $namelength, $publicid, $public, $publiclength, $systemid, $system, $systemlength);
    $context->{'nodeready'} = $TRUE;
}

sub scanner_state_bogus_comment
{
    my ($context) = @_;
    my ($datastartindex, $data, $datalength);

    $context->{'scannerstate'} = \&scanner_state_text;

    $datastartindex = ++$context->{'inbuffer'}{'index'};

    while (n(0) && c(0) != 0x3e) { # '>'
        $context->{'inbuffer'}{'index'}++;
    }

    $datalength = $context->{'inbuffer'}{'index'} - $datastartindex;

    if ($datalength) {
        $data                   = text($datastartindex, $datalength);
        $context->{'node'}      = node_create_comment(0, $data, $datalength);
        $context->{'nodeready'} = $TRUE;
    }
}

sub scanner_state_comment
{
    my ($context) = @_;
    my ($datastartindex, $data, $datalength);

    $context->{'scannerstate'} = \&scanner_state_text;

    $context->{'inbuffer'}{'index'} += 3;
    $datastartindex      = $context->{'inbuffer'}{'index'};
    $datalength          = 0;

    while (n(0)) {

        if (c(0) == 0x3e && c(-2) == 0x2d) { # '-*>'

            if (c(-1) == 0x2d) { # '-' для '-->'
                $datalength = -2;
                last;
            }

            if (c(-1) == 0x21 && c(-3) == 0x2d) {  # '-*!' для '--!>'
                $datalength = -3;
                last;
            }
        }

        $context->{'inbuffer'}{'index'}++;
    }

    $datalength += $context->{'inbuffer'}{'index'} - $datastartindex;
    # Учитывая отрицательную длину.
    if ($datalength > 0) {
        $data                   = text($datastartindex, $datalength);
        $context->{'node'}      = node_create_comment(0, $data, $datalength);
        $context->{'nodeready'} = $TRUE;
    }
}

sub scanner_state_cdata
{
    my ($context) = @_;
    my ($textdatastartindex, $textdata, $textdatalength);

    $context->{'scannerstate'} = \&scanner_state_text;

    $context->{'inbuffer'}{'index'} += 8;
    $textdatastartindex  = $context->{'inbuffer'}{'index'};
    $textdatalength      = 0;

    while (n(0)) {

        if (c(0) == 0x3e && c(-1) == 0x5d && c(-2) == 0x5d) { # ']]>'
            $textdatalength = -2;
            last;
        }

        $context->{'inbuffer'}{'index'}++;
    }

    $textdatalength += $context->{'inbuffer'}{'index'} - $textdatastartindex;
    # Учитывая отрицательную длину.
    if ($textdatalength > 0) {
        $textdata               = text($textdatastartindex, $textdatalength);
        $context->{'node'}      = node_create_comment(0, $textdata, $textdatalength);
        $context->{'nodeready'} = $TRUE;
    }
}

sub scanner_state_rawdata
{
    my ($context) = @_;
    my ($index, $charrefstartindex, $datastartindex, $charrefutf8, $data, $datalength);

    $context->{'scannerstate'} = \&scanner_state_rawdata_end;

    $datastartindex = $context->{'inbuffer'}{'index'};
    $datalength     = 0;

    while (n(0)) {

        if (c(0) == 0x3c && n($context->{'rawswitch'}{'len'} + 2) && c(1) == 0x2f) { # '<', '/'
            $index = 0;

            while ($index < $context->{'rawswitch'}{'len'}) {

                if (char_to_lower(c($index + 2)) != $context->{'rawswitch'}{'name'}[$index]) {
                    goto L;
                }

                $index++;
            }

            if (c($index + 2) == 0x3e || c($index + 2) == 0x2f || char_is_space(c($index + 2))) { # '>', '/'
                last;
            }
        L:
            $context->{'inbuffer'}{'index'} += $index + 2;
            next;
        }

        if (c(0) == 0x26 && $context->{'rawswitch'}{'chref'} && n(2)) { # '&'
            $charrefstartindex = $context->{'inbuffer'}{'index'};
            $charrefutf8       = charref_parse($context);

            if ($charrefutf8) {

                if ($datastartindex < $charrefstartindex) {
                    $datalength += $charrefstartindex - $datastartindex;
                    $data       .= text($datastartindex, $charrefstartindex - $datastartindex);
                }

                $datalength += $charrefutf8->[0];
                $data       .= pack("C$charrefutf8->[0]", @{$charrefutf8->[1]});

                $datastartindex = $context->{'inbuffer'}{'index'};
            }

            next;
        }

        $context->{'inbuffer'}{'index'}++;
    }

    if ($datastartindex < $context->{'inbuffer'}{'index'}) {
        $datalength += $context->{'inbuffer'}{'index'} - $datastartindex;
        $data       .= text($datastartindex, $context->{'inbuffer'}{'index'} - $datastartindex);
    }

    if ($datalength) {
        $context->{'node'}      = node_create_textnode(0, $data, $datalength);
        $context->{'nodeready'} = $TRUE;
    }
}

sub scanner_state_plaintext
{
    my ($context) = @_;
    my ($data, $datalength);

    $datalength = $context->{'inbuffer'}{'datalength'} - $context->{'inbuffer'}{'index'};

    if ($datalength) {
        $data              = text($context->{'inbuffer'}{'index'}, $datalength);
        $context->{'node'} = node_create_textnode(0, $data, $datalength);

        $context->{'nodeready'} = $TRUE;
        $context->{'inbuffer'}{'index'}    += $datalength;
    }
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#       Алгоритм:
#
# а) после открывающего тега '<script>', сканер переходит в состояние 'с1';
# б) если встретилась последовательность '<!--' в состоянии 'с1', сканер
#    переходит в состояние 'с2';
# в) если встретилась последовательность '-->' в любом состоянии ('с2', 'с3'),
#    то сканер переходит в состояние 'с1';
# г) если встретилась последовательность '<script[\s/>]' в состоянии 'с2',
#    сканер переходит в состояние 'с3';
# д) если встретилась последовательность '</script[\s/>]' в состоянии 'с3',
#    сканер переходит в состояние 'с2';
# е) если встретилась последовательность '</script[\s/>]' в любом другом
#    состоянии ('с1', 'с2'), то происходит останов сканера.
#
# my @inbuffer      = split(",", "<!--,<script>,</script>,<script>,</script>,-->,<!--,</script>");
# my $inbufferindex = 0;
#
# # с1 <- начальное состояние
# while ($inbufferindex < @inbuffer) {
#     last if $inbuffer[$inbufferindex] =~ /<\/script>/;
#
#     print "с1 $inbuffer[$inbufferindex]\n";
#
#     if ($inbuffer[$inbufferindex] =~ /<\!--/) {
#         # с2 <- состояние комментария
#         while (++$inbufferindex < @inbuffer) {
#             goto L2 if $inbuffer[$inbufferindex] =~ /<\/script>/;
#
#             print "с2 $inbuffer[$inbufferindex]\n";
#
#             last if $inbuffer[$inbufferindex] =~ /-->/;
#
#             if ($inbuffer[$inbufferindex] =~ /<script>/) {
#                 # с3 <- открытый тег в состоянии комментария
#                 while (++$inbufferindex < @inbuffer) {
#                     print "с3 $inbuffer[$inbufferindex]\n";
#
#                     goto L1 if $inbuffer[$inbufferindex] =~ /-->/;
#
#                     last if $inbuffer[$inbufferindex] =~ /<\/script>/;
#                 }
#             }
#         }
#     }
# L1:
#     $inbufferindex++;
# }
#
# L2: # EXIT
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub scanner_state_script
{
    my ($context) = @_;
    my ($datastartindex, $data, $datalength);

    $context->{'scannerstate'} = \&scanner_state_rawdata_end;

    $datastartindex = $context->{'inbuffer'}{'index'};
    # с1
    while (n(0)) {

        if (c(0) == 0x3c) { # '<'

            if (n(8) && c(1)                == 0x2f && # '/'
                        char_to_lower(c(2)) == 0x73 && # 's'
                        char_to_lower(c(3)) == 0x63 && # 'c'
                        char_to_lower(c(4)) == 0x72 && # 'r'
                        char_to_lower(c(5)) == 0x69 && # 'i'
                        char_to_lower(c(6)) == 0x70 && # 'p'
                        char_to_lower(c(7)) == 0x74 && # 't'
                       (c(8)                == 0x3e || # '>'
                        c(8)                == 0x2f || # '/'
                        char_is_space(c(8)))) {
                last;
            }

            if (n(3) && c(1) == 0x21 && c(2) == 0x2d && c(3) == 0x2d) { # '!--'
                $context->{'inbuffer'}{'index'} += 3;
                # с2
                while (1) {
                    $context->{'inbuffer'}{'index'}++;

                    if (!n(0)) {
                        goto L2;
                    }

                    if (c(0) == 0x3e && c(-1) == 0x2d && c(-2) == 0x2d) { # '-->'
                        last; # -> с1
                    }

                    if (c(0) == 0x3c) { # '<'

                        if (n(8) && c(1)                == 0x2f && # '/'
                                    char_to_lower(c(2)) == 0x73 && # 's'
                                    char_to_lower(c(3)) == 0x63 && # 'c'
                                    char_to_lower(c(4)) == 0x72 && # 'r'
                                    char_to_lower(c(5)) == 0x69 && # 'i'
                                    char_to_lower(c(6)) == 0x70 && # 'p'
                                    char_to_lower(c(7)) == 0x74 && # 't'
                                   (c(8)                == 0x3e || # '>'
                                    c(8)                == 0x2f || # '/'
                                    char_is_space(c(8)))) {
                            goto L2;
                        }

                        if (n(7) && char_to_lower(c(1)) == 0x73 && # 's'
                                    char_to_lower(c(2)) == 0x63 && # 'c'
                                    char_to_lower(c(3)) == 0x72 && # 'r'
                                    char_to_lower(c(4)) == 0x69 && # 'i'
                                    char_to_lower(c(5)) == 0x70 && # 'p'
                                    char_to_lower(c(6)) == 0x74 && # 't'
                                   (c(7)                == 0x3e || # '>'
                                    c(7)                == 0x2f || # '/'
                                    char_is_space(c(7)))) {
                            $context->{'inbuffer'}{'index'} += 7;
                            # с3
                            while (1) {
                                $context->{'inbuffer'}{'index'}++;

                                if (!n(0)) {
                                    goto L2;
                                }

                                if (c(0) == 0x3e && c(-1) == 0x2d && c(-2) == 0x2d) { # '-->'
                                    goto L1; # -> с1
                                }

                                if (n(8) && c(0)                == 0x3c && # '<'
                                            c(1)                == 0x2f && # '/'
                                            char_to_lower(c(2)) == 0x73 && # 's'
                                            char_to_lower(c(3)) == 0x63 && # 'c'
                                            char_to_lower(c(4)) == 0x72 && # 'r'
                                            char_to_lower(c(5)) == 0x69 && # 'i'
                                            char_to_lower(c(6)) == 0x70 && # 'p'
                                            char_to_lower(c(7)) == 0x74 && # 't'
                                           (c(8)                == 0x3e || # '>'
                                            c(8)                == 0x2f || # '/'
                                            char_is_space(c(8)))) {
                                   $context->{'inbuffer'}{'index'} += 8;
                                   last; # -> с2
                                }
                            } # ~ с3
                        }
                    }
                } # ~ с2
            }
        }
    L1:
        $context->{'inbuffer'}{'index'}++;
    } # ~ с1
L2:
    $datalength = $context->{'inbuffer'}{'index'} - $datastartindex;

    if ($datalength) {
        $data                   = text($datastartindex, $datalength);
        $context->{'node'}      = node_create_textnode(0, $data, $datastartindex);
        $context->{'nodeready'} = $TRUE;
    }
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Обработкой SVG и MathML должны заниматься отдельные парсеры, в текущей
# реализации используется данная заглушка.
# Кавычки на определяются, возможен ошибочный останов.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub scanner_state_foreigndata
{
    my ($context) = @_;
    my ($quote, $index, $datastartindex, $data, $datalength);

    $context->{'scannerstate'} = \&scanner_state_rawdata_end;

    $datastartindex = $context->{'inbuffer'}{'index'};

    while (n(0)) {

        if (c(0) == 0x3c) { # '<'

            if (n(3) && c(1) == 0x21 && c(2) == 0x2d && c(3) == 0x2d) { # '!--'
                $context->{'inbuffer'}{'index'} += 4;

                while (n(0)) {

                    if (c(0) == 0x3e && c(-2) == 0x2d && (c(-1) == 0x2d || (c(-1) == 0x21 && c(-3) == 0x2d))) { # '-*>' и '-' для '-->' или '-*!' для '--!>'
                        goto L2;
                    }

                    $context->{'inbuffer'}{'index'}++;
                }
                # EOF.
                last;
            }

            if (n($context->{'rawswitch'}{'len'} + 2) && c(1) == 0x2f) { # '/'
                $index = 0;

                while ($index < $context->{'rawswitch'}{'len'}) {

                    if (char_to_lower(c($index + 2)) != $context->{'rawswitch'}{'name'}[$index]) {
                        goto L1;
                    }

                    $index++;
                }

                if (c($index + 2) == 0x3e || c($index + 2) == 0x2f || char_is_space(c($index + 2))) { # '>', '/'
                    last;
                }
            L1:
                $context->{'inbuffer'}{'index'} += $index + 2;
                next;
            }
        }
    L2:
        $context->{'inbuffer'}{'index'}++;
    }

    $datalength = $context->{'inbuffer'}{'index'} - $datastartindex;

    if ($datalength) {
        $data                   = text($datastartindex, $datalength);
        $context->{'node'}      = node_create_textnode(0, $data, $datalength);
        $context->{'nodeready'} = $TRUE;
    }
}

sub scanner_state_rawdata_end
{
    my ($context) = @_;
    my ($quote);

    $context->{'scannerstate'} = \&scanner_state_text;

    $context->{'node'}   = node_create_endtag(0, $context->{'rawswitch'}{'id'}, text($context->{'inbuffer'}{'index'} + 1, $context->{'rawswitch'}{'len'}), $context->{'rawswitch'}{'len'});
    $context->{'inbuffer'}{'index'} += $context->{'rawswitch'}{'len'};

    $quote = '';

    if (c(1) == 0x3e) { # '>'
        $context->{'inbuffer'}{'index'}++;
    } else {
        # Пропуск возможных атрибутов с учетом кавычек.
        while (1) {
            $context->{'inbuffer'}{'index'}++;

            if (!n(0)) {
                return;
            }

            if (c(0) == 0x22 || c(0) == 0x27) { # ''', '"'

                if (!$quote) {
                    $quote = c(0);
                } elsif ($quote == c(0)) {
                    $quote = '';
                }

                next;
            }

            if (c(0) == 0x3e && !$quote) { # '>'
                last;
            }
        }
    }

    $context->{'nodeready'} = $TRUE;
}

1;