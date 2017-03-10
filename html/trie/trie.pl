use strict;

use utf8;
use POSIX;
use Getopt::Long;

my (
    $IF, $inputfile, $outputfile, $console,

    %documenttypes, %elements, %atributes, %events, @numericcharrefs, %namedcharrefs,
    $entry, $entryname, @value,

    @utf8, $index, $id, $name, $text,

    $documenttypetrieroots, $documenttypetrienodes,
    $elementtrieroots,      $elementtrienodes,
    $atributetrieroots,     $atributetrienodes,
    $eventtrieroots,        $eventtrienodes,
    $namedcharreftrieroots, $namedcharreftrienodes,

    $scopebitset1, $scopebitset2, $scopebitset3, $scopebitset4, $scopebitset5,
    $groupbitset1, $groupbitset2, $groupbitset3, $groupbitset4, $groupbitset5,
    $groupbitset6, $groupbitset7, $groupbitset8,

    $impliedendbitset1, $impliedendbitset2,

    $specialbitset1, $specialbitset2
);

$inputfile  = "data.txt";
$outputfile = "tries.pm";

GetOptions(
    'inputfile=s' => \$inputfile,
    'console'     => \$console # Флаг вывода на консоль.
);

open $IF, "<", $inputfile || die $!;

unless ($console) {
    open STDOUT, ">", $outputfile || die $!;
    binmode STDOUT, ":utf8";
}

#----- Наполнение именами ------------------------------------------------------
#-------------------------------------------------------------------------------

while (<$IF>) {
    # Пропуск комментариев и пустых строк.
    next if /^\s*(#|$)/;
    # Удаление начальных и замыкающих пробелыных символов (включая NL).
    s/^\s+|\s+$//g;

    if (/^\s*%(.+)/) {
        $entryname = $1;

        if ($entryname =~ /doctype\s*identifiers/i) {
            $entry = \%documenttypes;
        } elsif ($entryname =~ /elements/i) {
            $entry = \%elements;
        } elsif ($entryname =~ /attributes/i) {
            $entry = \%atributes;
        } elsif ($entryname =~ /events/i) {
            $entry = \%events;
        } elsif ($entryname =~ /numeric\s*character\s*references/i) {
            $entry = \@numericcharrefs;
        } elsif ($entryname =~ /named\s*character\s*references/i) {
            $entry = \%namedcharrefs;
        } else {
            die "#1: $entryname";
        }

        next;
    }

    @value = ();

    if ($entry == \%documenttypes) {
        ($name) = /^"(.+)"/;
    } elsif ($entry == \@numericcharrefs) {
        ($name, @value) = /^([^\s]+)\s+\[u\+(\w+)\]\s+\[(.+?)\s+\(/i;
        # Для числовых ссылок дерево не строится, создается массив с начальным индексом 0x80 (€).
        $numericcharrefs[hex($name) - 0x80] = [@value];
        next;

    } elsif ($entry == \%namedcharrefs) {
        ($name, @value) = /^([^\s]+)\s+\[u\+(\w+)(?:,u\+(\w+))?\]/i;
    } else {
        ($name) = /^([^\s]+)/;
    }
    # Все имена кроме именованных символьных ссылок в нижнем регистре.
    if ($entry != \%namedcharrefs) {
        $name = lc $name;
        # У событий удаляется префикс 'on-'.
        if ($entry == \%events) {
            $name =~ s/^on//;
        }
    }
    # Имя уже существует.
    die "#2: $name" if $entry->{$name};

    $entry->{$name}{'value'} = [@value];
}

#----- Присвоение ID -----------------------------------------------------------
#-------------------------------------------------------------------------------

foreach $entry (\%documenttypes, \%elements, \%atributes, \%events, \%namedcharrefs) {
    # Нулевой ID не используется.
    $id = 1;

    foreach (sort keys %$entry) {
        $entry->{$_}{'id'} = $id++;
    }
}

#----- Постороение префиксных деревьев -----------------------------------------
#-------------------------------------------------------------------------------

($documenttypetrieroots, $documenttypetrienodes) = trie_build(\%documenttypes);
($elementtrieroots,      $elementtrienodes)      = trie_build(\%elements);
($atributetrieroots,     $atributetrienodes)     = trie_build(\%atributes);
($eventtrieroots,        $eventtrienodes)        = trie_build(\%events);
($namedcharreftrieroots, $namedcharreftrienodes) = trie_build(\%namedcharrefs);

#----- Печать ------------------------------------------------------------------
#-------------------------------------------------------------------------------

print <<'END';
package WebGear::HTML::Tries;
use strict;

use Exporter qw(import);

our @EXPORT = do {
    no strict 'refs';

    map {

        if (/^(DOCUMENTTYPE|ELEMENT|ATTRIBUTE|EVENT)_|bitset/) {
            "\$$_"
        } elsif (/(charrefs|roots|nodes)/) {
            "\@$_"
        } else {
            ()
        }

    } keys %{__PACKAGE__ . '::'};
};
END

print <<'END';

#----- Константы ---------------------------------------------------------------
#-------------------------------------------------------------------------------
END

print <<'END';

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#       Типы документа
#
# https://html.spec.whatwg.org/multipage/syntax.html#the-initial-insertion-mode
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
END
foreach (sort keys %documenttypes) {
    $name = uc;
    $name =~ s/-|\s|\/|\.|\+|'|://g;

    printf "our \$DOCUMENTTYPE_%-58s = %3d; # \"%s\"\n", $name, $documenttypes{$_}{'id'}, $_;
}

print <<'END';

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#       Элементы
#
# https://html.spec.whatwg.org/multipage/indices.html#elements-3
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
END

foreach (sort keys %elements) {
    printf "our \$ELEMENT_%-22s = %3d;\n", uc $_, $elements{$_}{'id'};
}

print <<'END';

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#       Атрибуты
#
# https://html.spec.whatwg.org/multipage/indices.html#attributes-3
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
END
foreach (sort keys %atributes) {
    $name = uc;
    $name =~ tr/-/_/;

    printf "our \$ATTRIBUTE_%-20s = %3d;\n", $name, $atributes{$_}{'id'};
}

print <<'END';

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#       События
#
# https://html.spec.whatwg.org/multipage/indices.html#attributes-3
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
END
foreach (sort keys %events) {
    printf "our \$EVENT_%-24s = %3d;\n", uc 'on' . $_, $events{$_}{'id'};
}

print <<'END';

#----- Битовые маски -----------------------------------------------------------
# our $bitset = [
#   0x00200010,
#   0x04000000,
#   0x00400800,
#   0x26800000,
#   0x00000000];
#    |
#    +---------> Позиция бита в массиве соответствует значению ID элемента.
#
# Разрядность также учитывается в подпрограмме bitset_test парсера.
#-------------------------------------------------------------------------------
END

print <<'END';

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#       Области видмости 1
#
# https://html.spec.whatwg.org/multipage/syntax.html#has-an-element-in-scope
#
# Элементы: applet, caption, html, table, td, th, marquee, object, template
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
END

$scopebitset1 = bitset_build(\%elements, ['applet', 'caption', 'html', 'table',
                                          'td', 'th', 'marquee', 'object', 'template']);

printf "our \$scopebitset1 = [0x%08x, 0x%08x, 0x%08x, 0x%08x, 0x%08x];\n",
       $scopebitset1->[0], $scopebitset1->[1], $scopebitset1->[2], $scopebitset1->[3], $scopebitset1->[4];

print <<'END';

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#       Области видмости 2
#
# https://html.spec.whatwg.org/multipage/syntax.html#has-an-element-in-list-item-scope
#
# Элементы из "Области видмости 1" плюс: ol, ul
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
END

$scopebitset2 = bitset_build(\%elements, ['applet', 'caption', 'html', 'table',
                                          'td', 'th', 'marquee', 'object', 'template',
                                          'ol', 'ul']);

printf "our \$scopebitset2 = [0x%08x, 0x%08x, 0x%08x, 0x%08x, 0x%08x];\n",
       $scopebitset2->[0], $scopebitset2->[1], $scopebitset2->[2], $scopebitset2->[3], $scopebitset2->[4];

print <<'END';

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#       Области видмости 3
#
# https://html.spec.whatwg.org/multipage/syntax.html#has-an-element-in-button-scope
#
# Элементы из "Области видмости 1" плюс: button
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
END

$scopebitset3 = bitset_build(\%elements, ['applet', 'caption', 'html', 'table',
                                          'td', 'th', 'marquee', 'object', 'template',
                                          'button']);

printf "our \$scopebitset3 = [0x%08x, 0x%08x, 0x%08x, 0x%08x, 0x%08x];\n",
       $scopebitset3->[0], $scopebitset3->[1], $scopebitset3->[2], $scopebitset3->[3], $scopebitset3->[4];

print <<'END';

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#       Области видмости 4
#
# https://html.spec.whatwg.org/multipage/syntax.html#has-an-element-in-table-scope
#
# Элементы: html, table, template
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
END

$scopebitset4 = bitset_build(\%elements, ['html', 'table', 'template']);

printf "our \$scopebitset4 = [0x%08x, 0x%08x, 0x%08x, 0x%08x, 0x%08x];\n",
       $scopebitset4->[0], $scopebitset4->[1], $scopebitset4->[2], $scopebitset4->[3], $scopebitset4->[4];

print <<'END';

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#       Области видмости 5
#
# https://html.spec.whatwg.org/multipage/syntax.html#has-an-element-in-select-scope
#
# Все элементы за исключением: optgroup, option
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
END

$scopebitset5 = bitset_build(\%elements, ['optgroup', 'option'], 'exclude');

printf "our \$scopebitset5 = [0x%08x, 0x%08x, 0x%08x, 0x%08x, 0x%08x];\n",
       $scopebitset5->[0], $scopebitset5->[1], $scopebitset5->[2], $scopebitset5->[3], $scopebitset5->[4];

print <<'END';

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#       Группа 1
#
# Элементы: h1, h2, h3, h4, h5, h6
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
END

$groupbitset1 = bitset_build(\%elements, ['h1', 'h2', 'h3', 'h4', 'h5', 'h6']);

printf "our \$groupbitset1 = [0x%08x, 0x%08x, 0x%08x, 0x%08x, 0x%08x];\n",
       $groupbitset1->[0], $groupbitset1->[1], $groupbitset1->[2], $groupbitset1->[3], $groupbitset1->[4];

print <<'END';

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#       Группа 2
#
# Элементы: td, th
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
END

$groupbitset2 = bitset_build(\%elements, ['td', 'th']);

printf "our \$groupbitset2 = [0x%08x, 0x%08x, 0x%08x, 0x%08x, 0x%08x];\n",
       $groupbitset2->[0], $groupbitset2->[1], $groupbitset2->[2], $groupbitset2->[3], $groupbitset2->[4];

print <<'END';

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#       Группа 3
#
# Элементы: tbody, thead, tfoot
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
END

$groupbitset3 = bitset_build(\%elements, ['tbody', 'thead', 'tfoot']);

printf "our \$groupbitset3 = [0x%08x, 0x%08x, 0x%08x, 0x%08x, 0x%08x];\n",
       $groupbitset3->[0], $groupbitset3->[1], $groupbitset3->[2], $groupbitset3->[3], $groupbitset3->[4];

print <<'END';

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#       Группа 4
#
# Элементы из "Группа 2" плюс: html
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
END

$groupbitset4 = bitset_build(\%elements, ['td', 'th', 'html']);

printf "our \$groupbitset4 = [0x%08x, 0x%08x, 0x%08x, 0x%08x, 0x%08x];\n",
       $groupbitset4->[0], $groupbitset4->[1], $groupbitset4->[2], $groupbitset4->[3], $groupbitset4->[4];

print <<'END';

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#       Группа 5
#
# Элементы из "Группа 1" плюс: html
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
END

$groupbitset5 = bitset_build(\%elements, ['h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'html']);

printf "our \$groupbitset5 = [0x%08x, 0x%08x, 0x%08x, 0x%08x, 0x%08x];\n",
       $groupbitset5->[0], $groupbitset5->[1], $groupbitset5->[2], $groupbitset5->[3], $groupbitset5->[4];

print <<'END';

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#       Группа 6
#
# Элементы: table, template, html
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
END

$groupbitset6 = bitset_build(\%elements, ['table', 'template', 'html']);

printf "our \$groupbitset6 = [0x%08x, 0x%08x, 0x%08x, 0x%08x, 0x%08x];\n",
       $groupbitset6->[0], $groupbitset6->[1], $groupbitset6->[2], $groupbitset6->[3], $groupbitset6->[4];

print <<'END';

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#       Группа 7
#
# Элементы: tr, template, html
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
END

$groupbitset7 = bitset_build(\%elements, ['tr', 'template', 'html']);

printf "our \$groupbitset7 = [0x%08x, 0x%08x, 0x%08x, 0x%08x, 0x%08x];\n",
       $groupbitset7->[0], $groupbitset7->[1], $groupbitset7->[2], $groupbitset7->[3], $groupbitset7->[4];

print <<'END';

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#       Группа 8
#
# Элементы: tbody, tfoot, thead, template html
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
END

$groupbitset8 = bitset_build(\%elements, ['tbody', 'tfoot', 'thead', 'template', 'html']);

printf "our \$groupbitset8 = [0x%08x, 0x%08x, 0x%08x, 0x%08x, 0x%08x];\n",
       $groupbitset8->[0], $groupbitset8->[1], $groupbitset8->[2], $groupbitset8->[3], $groupbitset8->[4];

print <<'END';

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#       Implied end tags
#
# https://html.spec.whatwg.org/multipage/syntax.html#generate-implied-end-tags
#
# Все элементы за исключением: dd, dt, li, optgroup, option, p, rb, rp, rt, rtc
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
END

$impliedendbitset1 = bitset_build(\%elements, ['dd', 'dt', 'li', 'optgroup',
                                               'option', 'p', 'rb', 'rp', 'rt', 'rtc'],
                                               'exclude');

printf "our \$impliedendbitset1 = [0x%08x, 0x%08x, 0x%08x, 0x%08x, 0x%08x];\n",
       $impliedendbitset1->[0], $impliedendbitset1->[1], $impliedendbitset1->[2], $impliedendbitset1->[3], $impliedendbitset1->[4];

print <<'END';

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#       "Implied end tags" в состоянии "in body" для элементов: rp, rt
#
# Элементы из "Implied end tags" за исключением: rtc
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
END

$impliedendbitset2 = bitset_build(\%elements, ['dd', 'dt', 'li', 'optgroup',
                                               'option', 'p', 'rb', 'rp', 'rt'],
                                               'exclude');

printf "our \$impliedendbitset2 = [0x%08x, 0x%08x, 0x%08x, 0x%08x, 0x%08x];\n",
       $impliedendbitset2->[0], $impliedendbitset2->[1], $impliedendbitset2->[2], $impliedendbitset2->[3], $impliedendbitset2->[4];

print <<'END';

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#       Категория "Special"
#
# https://html.spec.whatwg.org/multipage/syntax.html#special
#
# Элементы: address, applet, area, article, aside, base, basefont, bgsound,
# blockquote, body, br, button, caption, center, col, colgroup, dd, details, dir,
# div, dl, dt, embed, fieldset, figcaption, figure, footer, form, frame, frameset,
# h1, h2, h3, h4, h5, h6, head, header, hgroup, hr, html, iframe, img, input, li,
# link, listing, main, marquee, menu, meta, nav, noembed, noframes, noscript,
# object, ol, p, param, plaintext, pre, script, section, select, source, style,
# summary, table, tbody, td, template, textarea, tfoot, th, thead, title, tr,
# track, ul, wbr
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
END

$specialbitset1 = bitset_build(\%elements, ['address', 'applet', 'area', 'article',
                                            'aside', 'base', 'basefont', 'bgsound',
                                            'blockquote', 'body', 'br', 'button',
                                            'caption', 'center', 'col', 'colgroup',
                                            'dd', 'details', 'dir', 'div', 'dl',
                                            'dt', 'embed', 'fieldset', 'figcaption',
                                            'figure', 'footer', 'form', 'frame',
                                            'frameset', 'h1', 'h2', 'h3', 'h4',
                                            'h5', 'h6', 'head', 'header', 'hgroup',
                                            'hr', 'html', 'iframe', 'img', 'input',
                                            'li', 'link', 'listing', 'main',
                                            'marquee', 'menu', 'meta', 'nav',
                                            'noembed', 'noframes', 'noscript',
                                            'object', 'ol', 'p', 'param', 'plaintext',
                                            'pre', 'script', 'section', 'select',
                                            'source', 'style', 'summary', 'table',
                                            'tbody', 'td', 'template', 'textarea',
                                            'tfoot', 'th', 'thead', 'title', 'tr',
                                            'track', 'ul', 'wbr']);

printf "our \$specialbitset1 = [0x%08x, 0x%08x, 0x%08x, 0x%08x, 0x%08x];\n",
       $specialbitset1->[0], $specialbitset1->[1], $specialbitset1->[2], $specialbitset1->[3], $specialbitset1->[4];

print <<'END';

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#       Категория "Special" в состоянии "in body" для элементов: "li", "dd", "dt"
#
# Элементы из "Special" за исключением: address, div, p
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
END

$specialbitset2 = bitset_build(\%elements, ['applet', 'area', 'article', 'aside',
                                            'base', 'basefont', 'bgsound',
                                            'blockquote', 'body', 'br', 'button',
                                            'caption', 'center', 'col', 'colgroup',
                                            'dd', 'details', 'dir', 'dl', 'dt',
                                            'embed', 'fieldset', 'figcaption',
                                            'figure', 'footer', 'form', 'frame',
                                            'frameset', 'h1', 'h2', 'h3', 'h4',
                                            'h5', 'h6', 'head', 'header', 'hgroup',
                                            'hr', 'html', 'iframe', 'img',
                                            'input', 'li', 'link', 'listing',
                                            'main', 'marquee', 'menu', 'meta',
                                            'nav', 'noembed', 'noframes', 'noscript',
                                            'object', 'ol', 'param', 'plaintext',
                                            'pre', 'script', 'section', 'select',
                                            'source', 'style', 'summary', 'table',
                                            'tbody', 'td', 'template', 'textarea',
                                            'tfoot', 'th', 'thead', 'title',
                                            'tr', 'track', 'ul', 'wbr']);

printf "our \$specialbitset2 = [0x%08x, 0x%08x, 0x%08x, 0x%08x, 0x%08x];\n",
       $specialbitset2->[0], $specialbitset2->[1], $specialbitset2->[2], $specialbitset2->[3], $specialbitset2->[4];

#print <<'END';
#
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##       Категория "Formatting"
##
## https://html.spec.whatwg.org/multipage/syntax.html#formatting
##
## Элементы: a, b, big, code, em, font, i, nobr, s, small, strike, strong, tt, u
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#END
#
#my $formattingbitset = bitset_build(\%elements, ['a', 'b', 'big', 'code', 'em',
#                                                 'font', 'i', 'nobr', 's', 'small',
#                                                 'strike', 'strong', 'tt', 'u']);
#
#printf("our \$formattingbitset = [0x%08x, 0x%08x, 0x%08x, 0x%08x, 0x%08x];\n",
#       $formattingbitset->[0], $formattingbitset->[1], $formattingbitset->[2], $formattingbitset->[3], $formattingbitset->[4]);

print <<'END';

#----- Числовые и символьные ссылки --------------------------------------------
# our @numericcharrefs = (
#      ...
#     [0x06, [0xe2, 0x8a, 0x82, 0xe2, 0x83, 0x92]],
#       |      |     |     |     |     |     |
#       |      |     |     |     |     |     |
#       |      +-----+-----+-----+-----+-----+----> Байтовый массив UTF8 кода символа.
#       +-----------------------------------------> Количество байт в массиве:
#                                                   1-3 байт у числовых ссылок,
#                                                   1-6 байт у символьных ссылок.
#      ...
#
# Нулевой индекс в символьных ссылка не используется и содержит нули.
# Для числовых ссылок индекс вычисляется как СИМВОЛ - 0x80.
#-------------------------------------------------------------------------------
END

print <<'END';

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#       Числовые ссылки
#
# https://html.spec.whatwg.org/multipage/syntax.html#numeric-character-reference-end-state
#
# Индекс в массиве = СИМВОЛ - 0x80.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
END
print "our \@numericcharrefs = (\n";

for ($index = 0; $index < @numericcharrefs; $index++) {
    @utf8 = ucs4_to_utf8(hex $numericcharrefs[$index][0]);

    $text = '';
    $text .= sprintf "0x%02x",   $utf8[0][0] if $utf8[0][0];
    $text .= sprintf ", 0x%02x", $utf8[0][1] if $utf8[0][1];
    $text .= sprintf ", 0x%02x", $utf8[0][2] if $utf8[0][2];

    printf "\t[0x%02x, %18s]%s # %s\n",
           scalar @{$utf8[0]},
           $text ? "[$text]" : "undef",
           $index < $#numericcharrefs ? ", " : ");",
           $numericcharrefs[$index][1];
}

print <<'END';

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#       Символьные ссылки
#
# https://html.spec.whatwg.org/multipage/syntax.html#named-character-references
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
END
print "our \@namedcharrefs = (\n    [0x00,                                undef],  #\n";

foreach (sort keys %namedcharrefs) {
    @utf8 = (ucs4_to_utf8(hex $namedcharrefs{$_}{'value'}[0]), ucs4_to_utf8(hex $namedcharrefs{$_}{'value'}[1]));

    $text = '';
    $text .= sprintf "0x%02x",   $utf8[0][0] if $utf8[0][0];
    $text .= sprintf ", 0x%02x", $utf8[0][1] if $utf8[0][1];
    $text .= sprintf ", 0x%02x", $utf8[0][2] if $utf8[0][2];
    $text .= sprintf ", 0x%02x", $utf8[1][0] if $utf8[1][0];
    $text .= sprintf ", 0x%02x", $utf8[1][1] if $utf8[1][1];
    $text .= sprintf ", 0x%02x", $utf8[1][2] if $utf8[1][2];

    printf "    [0x%02x, %36s]%s # %s\n",
           scalar @{$utf8[0]} + scalar @{$utf8[1]},
           $text ? "[$text]" : "undef",
           $namedcharrefs{$_}{'id'} < keys %namedcharrefs ? ", " : ");",
           $_;
}

print <<'END';

#----- Корневые индексы --------------------------------------------------------
# our @roots = (
#     ...
#     0x0123, # [32] -> Индекс соответствует символу в таблице ASCII.
#      |
#      +----> Начальный индекс в массиве узлов перефиксного дерева.
#     ...
#
# Нулевой индекс не используется и содержит нули.
# Все имена кроме именованных символьных ссылок представлены в дереве в нижнем
# регистре.
#-------------------------------------------------------------------------------
END

print <<'END';

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#       Типы документа
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
END

print "our \@documenttypetrieroots = (\n    ";

for ($index = 0x00; $index <= 0xff; $index++) {
    printf "0x%04x%s",
           $documenttypetrieroots->[$index],
           $index < 0xff ? (($index + 1)  % 10 ? ", " : ",\n    ") : ");";
}


print <<'END';


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#       Элементы
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
END
print "our \@elementtrieroots = (\n    ";

for ($index = 0x00; $index <= 0xff; $index++) {
    printf "0x%04x%s",
           $elementtrieroots->[$index],
           $index < 0xff ? (($index + 1)  % 10 ? ", " : ",\n    ") : ");";
}


print <<'END';


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#       Атрибуты
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
END
print "our \@atributetrieroots = (\n    ";

for ($index = 0x00; $index <= 0xff; $index++) {
    printf "0x%04x%s",
           $atributetrieroots->[$index],
           $index < 0xff ? (($index + 1)  % 10 ? ", " : ",\n    ") : ");";
}

print <<'END';


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#       События
#
# Имена событий без префикса 'on-'.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
END
print "our \@eventtrieroots = (\n    ";

for ($index = 0x00; $index <= 0xff; $index++) {
    printf "0x%04x%s",
           $eventtrieroots->[$index],
           $index < 0xff ? (($index + 1)  % 10 ? ", " : ",\n    ") : ");";
}

print <<'END';


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#       Именованные ссылки
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
END
print "our \@namedcharreftrieroots = (\n    ";

for ($index = 0x00; $index <= 0xff; $index++) {
    printf "0x%04x%s",
           $namedcharreftrieroots->[$index],
           $index < 0xff ? (($index + 1)  % 10 ? ", " : ",\n    ") : ");";
}

print <<'END';



#-------------------------------------------------------------------------------
#       Префиксные деревья как массивы узлов
#
# our @dnodes = (
#     ...
#     [0x61, 0x0002, 0x0000, 0x00],
#       |       |       |     |
#       |       |       |     +---> Значение.
#       |       |       +---------> Следующий индекс для 'gt' ветви.
#       |       +-----------------> Следующий индекс для 'eq' ветви.
#       +-------------------------> Ключевой символ.
#     ...
#
# Ключевые слова отсортированы по возрастанию, поэтому 'lt' ветвь отсутствует.
# Нулевой индекс не используется и содержит нули.
#-------------------------------------------------------------------------------
END

print <<'END';

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#       Типы документа
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
END
print "our \@documenttypetrienodes = (\n    ";

for ($index = 0; $index < @$documenttypetrienodes; $index++) {
    printf "[0x%02x, 0x%04x, 0x%04x, 0x%02x]%s",
           ord $documenttypetrienodes->[$index]{'key'},
           # Для 'eq' и 'gt' ветвей, заменяем ссылки на индекс в массиве узлов.
           $documenttypetrienodes->[$index]{'eq'}{'i'},
           $documenttypetrienodes->[$index]{'gt'}{'i'},
           $documenttypetrienodes->[$index]{'value'},
           $index < $#$documenttypetrienodes ? (($index + 1) % 5 ? ", " : ",\n    ") : ");";
}


print <<'END';


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#       Элементы
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
END
print "our \@elementtrienodes = (\n    ";

for ($index = 0; $index < @$elementtrienodes; $index++) {
    printf "[0x%02x, 0x%04x, 0x%04x, 0x%02x]%s",
           ord $elementtrienodes->[$index]{'key'},
           $elementtrienodes->[$index]{'eq'}{'i'},
           $elementtrienodes->[$index]{'gt'}{'i'},
           $elementtrienodes->[$index]{'value'},
           $index < $#$elementtrienodes ? (($index + 1) % 5 ? ", " : ",\n    ") : ");";
}



print <<'END';


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#       Атрибуты
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
END
print "our \@atributetrienodes = (\n    ";

for ($index = 0; $index < @$atributetrienodes; $index++) {
    printf "[0x%02x, 0x%04x, 0x%04x, 0x%02x]%s",
           ord $atributetrienodes->[$index]{'key'},
           $atributetrienodes->[$index]{'eq'}{'i'},
           $atributetrienodes->[$index]{'gt'}{'i'},
           $atributetrienodes->[$index]{'value'},
           $index < $#$atributetrienodes ? (($index + 1) % 5 ? ", " : ",\n    ") : ");";
}

print <<'END';


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#       События
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
END
print "our \@eventtrienodes = (\n    ";

for ($index = 0; $index < @$eventtrienodes; $index++) {
    printf "[0x%02x, 0x%04x, 0x%04x, 0x%02x]%s",
           ord $eventtrienodes->[$index]{'key'},
           $eventtrienodes->[$index]{'eq'}{'i'},
           $eventtrienodes->[$index]{'gt'}{'i'},
           $eventtrienodes->[$index]{'value'},
           $index < $#$eventtrienodes ? (($index + 1) % 5 ? ", " : ",\n    ") : ");";
}

print <<'END';


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#       Именованные ссылки
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
END
print "our \@namedcharreftrienodes = (\n    ";

for ($index = 0; $index < @$namedcharreftrienodes; $index++) {
    printf "[0x%02x, 0x%04x, 0x%04x, 0x%04x]%s",
           ord $namedcharreftrienodes->[$index]{'key'},
           $namedcharreftrienodes->[$index]{'eq'}{'i'},
           $namedcharreftrienodes->[$index]{'gt'}{'i'},
           $namedcharreftrienodes->[$index]{'value'},
           $index < $#$namedcharreftrienodes ? (($index + 1) % 5 ? ", " : ",\n    ") : ");";
}

print "\n1;\n";

#----- Битовые маски -----------------------------------------------------------
#
# http://www.coranac.com/documents/working-with-bits-and-bitfields/
#
# Установка: [ЗНАЧЕНИЕ >> РАЗМЕР] |= 1 << (ЗНАЧЕНИЕ & БИТ-1)
# Сброс:     [ЗНАЧЕНИЕ >> РАЗМЕР] &= ~(1 << (ЗНАЧЕНИЕ & БИТ-1))
# Проверка:  [ЗНАЧЕНИЕ >> РАЗМЕР] &  1 << (ЗНАЧЕНИЕ & БИТ-1)
#-------------------------------------------------------------------------------

sub bitset_build
{
    my ($entry, $names, $exclude) = @_;
    my ($bits, $size, @bitset, $name);
    # Количество бит (учитывается в  bitset_test() парсера).
    $bits = 32;
    # Округляем в большую сторону.
    $size = ceil(keys(%$entry) / $bits);

    if ($exclude) {

        foreach (keys %$entry) {

            foreach $name (@$names) {

                if ($_ eq $name) {
                    goto L;
                }
            }

            $bitset[$entry->{$_}{'id'} >> $size] |= 1 << ($entry->{$_}{'id'} & ($bits - 1));
        L:
        }

    } else {

        foreach $_ (@$names) {
            $bitset[$entry->{$_}{'id'} >> $size] |= 1 << ($entry->{$_}{'id'} & ($bits - 1));
        }
    }

    return \@bitset;
}

#----- Префиксное дерево -------------------------------------------------------
#-------------------------------------------------------------------------------

sub trie_build
{
    my ($entry) = @_;
    my ($trie, @roots, @nodes, $char);
    # Нулевой индекс не используется.
    $nodes[0] = undef;

    foreach (sort keys %$entry) {
        # Первая буква имени.
        $char = substr $_, 0, 1;
        # Буква появилась впервые.
        if ($trie->{'key'} ne $char) {
            # Новое поддерево.
            $trie = undef;
            # Начальный индекс в дереве.
            $roots[ord $char] = @nodes;
        }

        $trie = trie_insert_node(\@nodes, $trie, $_, $entry->{$_}{'id'});
    }
    # Тестирование.
    foreach (sort keys %$entry) {
        die "#3: $_" if $entry->{$_}{'id'} != trie_search(\@roots, \@nodes, [unpack "C*", $_]);
    }

    return (\@roots, \@nodes);
}

sub trie_insert_node
{
    my ($nodes, $parent, $name, $value) = @_;
    my ($key, $restname);
    # Первый символ имени ключа.
    $key = substr $name, 0, 1;
    # Оставшиеся символы в имени.
    $restname = substr $name, 1;
    # Новваю ветвь.
    unless ($parent) {
        $parent = {
            # Ключевой символ узла.
            'key' => $key,
            # Индекс в массиве узлов с учетом плюс неиспользуемый нулевой индекс.
            'i'   => $#$nodes + 1
        };

        push @$nodes, $parent;
    }
    # 'lt' ветвь.
    if ($key lt $parent->{'key'}) {
        $parent->{'lt'} = trie_insert_node($nodes, $parent->{'lt'}, $name, $value);
    # 'eq' ветвь.
    } elsif ($key eq $parent->{'key'}) {

        if ($restname) {
            $parent->{'eq'} = trie_insert_node($nodes, $parent->{'eq'}, $restname, $value);
        } else {
            $parent->{'value'} = $value;
        }
    # 'gt' ветвь.
    } elsif ($key gt $parent->{'key'}) {
        $parent->{'gt'} = trie_insert_node($nodes, $parent->{'gt'}, $name, $value);
    }

    return $parent;
}

sub trie_search
{
    my ($roots, $nodes, $data) = @_;
    my ($dataindex, $trieindex);

    $dataindex = 0;
    $trieindex = $roots->[$data->[0]];

    while ($trieindex != 0) {

        if (chr $data->[$dataindex] eq $nodes->[$trieindex]{'key'}) {
            last if ++$dataindex >= @$data;
            $trieindex = $nodes->[$trieindex]{'eq'}{'i'};
        } elsif (chr $data->[$dataindex] lt $nodes->[$trieindex]{'key'}) {
            $trieindex = $nodes->[$trieindex]{'lt'}{'i'};
        } elsif (chr $data->[$dataindex] gt $nodes->[$trieindex]{'key'}) {
            $trieindex = $nodes->[$trieindex]{'gt'}{'i'};
        } else {
            last;
        }
    }

    return $nodes->[$trieindex]{'value'};
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Версия из http://cdexos.sourceforge.net/ файла .../cdexos/libutf8/utf8.c
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub ucs4_to_utf8 {
    my ($ucs4) = @_;
    my (@utf8);
    # Может вызываться с нулем или неопределенным значением.
    return [] unless $ucs4;
    # "UNICODE_BAD_INPUT".
    die "#4: $ucs4" if $ucs4 <= 0 || $ucs4 > 0x7FFFFFFF;
	# Количество байт для кодирования (не больше четырех).
    goto L0 if $ucs4 < 0x80;
    goto L1 if $ucs4 < 0x800;
    goto L2 if $ucs4 < 0x10000e;
    #          $ucs4 < 0x200000;
    # Дальше идут проваливания.
    $utf8[3] = 0x80 | ($ucs4 & 0x3F);
    $ucs4 = ($ucs4 >> 6) | 0x10000;
L2:
    $utf8[2] = 0x80 | ($ucs4 & 0x3F);
    $ucs4 = ($ucs4 >> 6) | 0x800;
L1:
    $utf8[1] = 0x80 | ($ucs4 & 0x3F);
    $ucs4 = ($ucs4 >> 6) | 0xC0;
L0:
    $utf8[0] = $ucs4;

	return \@utf8;
}
