#===============================================================================
#       Вспомогательные подпрограммы
#===============================================================================

package WebGear::HTML::Utilities;
use strict;

use Exporter qw(import);
our @EXPORT = qw(
    trie_search
    trie_search_case_insensitive
    charref_parse
);
   
use WebGear::HTML::Filter;
use WebGear::HTML::Constants; 
use WebGear::HTML::Tries;

#----- Префиксное дерево -------------------------------------------------------
#------------------------------------------------------------------------------- 

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Во время поиске в префиксном дереве учитывается возможное вхождение подстроки 
# в строку, что наиболее критично для символьных ссылок.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub trie_search
{
    my ($context, $trie, $trieindex) = @_;
    my ($nameendindex, $value, $char);
    
    $value = $UNKNOWN;
    
    while ($trieindex && $context->{'inbuffer'}{'index'} < $context->{'inbuffer'}{'datalength'}) {
        $char = $context->{'inbuffer'}{'data'}[$context->{'inbuffer'}{'index'}];
    
        if ($char == $trie->[$trieindex][0]) {
        
            if ($trie->[$trieindex][3]) {
                $value        = $trie->[$trieindex][3];
                $nameendindex = $context->{'inbuffer'}{'index'};
            }

            $trieindex = $trie->[$trieindex][1];
            
            $context->{'inbuffer'}{'index'}++;
        } elsif ($char > $trie->[$trieindex][0]) { 
            $trieindex = $trie->[$trieindex][2];
        # Ключевые слова отсортированы по возрастанию, поэтому 'lt' ветвь отсутствует.
        } else {
            last;
        }
    }
    # При найденном значение, индекс в буфере устанавливается на следующий символ
    # после имени.
    if ($value) {
        $context->{'inbuffer'}{'index'} = $nameendindex + 1;
    }
    
    return $value;
}

sub trie_search_case_insensitive
{
    # my ($buffer, $bufferlength, $bufferindex, $trie, $trieindex) = @_;
    # my ($value, $char);
    
    # $value = $UNKNOWN;
    
    # while ($trieindex && $$bufferindex < $bufferlength) {
        # $char = char_to_lower($buffer->[$$bufferindex]);
    
        # if ($char == $trie->[$trieindex][0]) {     # 'key'
            # $value     = $trie->[$trieindex][3];
            # $trieindex = $trie->[$trieindex][1];   # 'eq'
            
            # $$bufferindex++;
        # } elsif ($char > $trie->[$trieindex][0]) { # 'gt'
            # $trieindex = $trie->[$trieindex][2];
        # } else {
            # last;
        # }
    # }
    #
    # return $value;
    
    my ($context, $trie, $trieindex) = @_;
    my ($nameendindex, $value, $char);
    
    $value = $UNKNOWN;
    
    while ($trieindex && $context->{'inbuffer'}{'index'} < $context->{'inbuffer'}{'datalength'}) {
        $char = char_to_lower($context->{'inbuffer'}{'data'}[$context->{'inbuffer'}{'index'}]);

        if ($char == $trie->[$trieindex][0]) {     # 'key'
        
            if ($trie->[$trieindex][3]) {
                $value        = $trie->[$trieindex][3];
                $nameendindex = $context->{'inbuffer'}{'index'};
            }

            $trieindex = $trie->[$trieindex][1];   # 'eq'
            
            $context->{'inbuffer'}{'index'}++;
        } elsif ($char > $trie->[$trieindex][0]) { # 'gt'
            $trieindex = $trie->[$trieindex][2];
        } else {
            last;
        }
    }
    
    if ($value) {
        $context->{'inbuffer'}{'index'} = $nameendindex + 1;
    }
    
    return $value;
}

#----- Ссылки ------------------------------------------------------------------
#------------------------------------------------------------------------------- 

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
# При вызове ожидается, что индекс указывает на '&' и доступно как минимум два 
# символа после него при выходе индекс установлен на первый невалидный символ.
# Во время разбора именованной ссылки необходимо учитывать как вхождение одного
# имени в другое, как и наличие символа ';', например:
# для строки "a &notin b" пропущен обязательный символ ';' имени 'notin'
# но есть вхождение 'not' для которого данный символ не обязателен, поэтому
# результат будет 'a' + '&not' + 'in b'. 
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub charref_parse
{
    my ($context) = @_;    
    my ($base, $flag, $total, $namedcharrefid, $utf8); 
    
    $context->{'inbuffer'}{'index'}++;
 
    if (c(0) == 0x23) { # '#'        
        $context->{'inbuffer'}{'index'}++;
        
        if (char_to_lower(c(0)) == 0x78) {  # 'x'
            $base = 16;
            $flag = 2; # HEX
           
            $context->{'inbuffer'}{'index'}++;
        } else {
            $base = 10;
            $flag = 1; # DEC
        }
        # Первый символ невалидный, например: '&##'.
        if (!char_is(c(0), $flag)) {
            return $NULL;
        } 
        
        $total = 0; 
        
        while (1) {

            if ($total < 0x10ffff) {
                ($total *= $base) += char_to_digit(c(0));
            }
            # Первый символ перед циклом.
            $context->{'inbuffer'}{'index'}++;
            
            if (!n(0)) {
                last;
            }
            
            if (!char_is(c(0), $flag)) { 
            
                if (c(0) == 0x3b) { # ';'
                    $context->{'inbuffer'}{'index'}++;
                }

                last;
            }
        }

        if ($total == 0 || $total > 0x10ffff || ($total >= 0xd800 && $total <= 0xdfff)) {
            return [0x03, [0xef, 0xbf, 0xbd]]; # Заменяющий символ U+FFFD.
        } 
        # Cимволы 0x81, 0x8d, 0x8f, 0x90, 0x9d не отправляются.
        if ($total >= 0x80 && $total <= 0x9f && $numericcharrefs[$total - 0x80][0]) {
            return $numericcharrefs[$total - 0x80]; 
        }
        # Версия из http://cdexos.sourceforge.net/ файла .../cdexos/libutf8/utf8.c
        # Нулевой индекс содержит количество байт.
        $utf8 = [0, [0, 0, 0, 0]];
        # Считаем что ucs4 == total и кодируем значение максимум четырмя байтами.
        goto L0 if $total < 0x80;
        goto L1 if $total < 0x800;
        goto L2 if $total < 0x10000e; 
        #          $total < 0x200000;
        # Дальше проваливания.
        $utf8->[1][3] = 0x80 | ($total & 0x3F);
        $total = ($total >> 6) | 0x10000;
        $utf8->[0]++;
    L2:
        $utf8->[1][2] = 0x80 | ($total & 0x3F);
        $total = ($total >> 6) | 0x800;
        $utf8->[0]++;
    L1:
        $utf8->[1][1] = 0x80 | ($total & 0x3F);
        $total = ($total >> 6) | 0xC0;
        $utf8->[0]++;
    L0:
        $utf8->[1][0] = $total;
        $utf8->[0]++;
        
        return $utf8;
    } 
     
    $namedcharrefid = trie_search($context, \@namedcharreftrienodes, $namedcharreftrieroots[c(0)]);

    if (!$namedcharrefid) {
        return $NULL;
    }
    # Если текущий символ ';' и имя ссылки не заканчивается на ';'.
    if (n(0) && c(0) == 0x3b && c(-1) != 0x3b) { # ';;'
        $context->{'inbuffer'}{'index'}++;
    }

    return $namedcharrefs[$namedcharrefid];
}

1;