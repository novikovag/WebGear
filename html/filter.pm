#===============================================================================
#       "Макросы"
#===============================================================================

package WebGear::HTML::Filter;
use strict;

use Filter::Simple;

FILTER 
{ 
    #----- Сканер --------------------------------------------------------------
    #---------------------------------------------------------------------------
    
    # Граница буфера.
    s/\bn\(0\)/(\$context->{'inbuffer'}{'index'} < \$context->{'inbuffer'}{'datalength'})/g; # n(0)
    s/\bn\((.+?)\)/(\$context->{'inbuffer'}{'index'} + $1 < \$context->{'inbuffer'}{'datalength'})/g;
    # Символ по индексу в буфере.
    s/\bc\(0\)/\$context->{'inbuffer'}{'data'}[\$context->{'inbuffer'}{'index'}]/g; # ch(0)
    s/\bc\((.+?)\)/\$context->{'inbuffer'}{'data'}[\$context->{'inbuffer'}{'index'} + $1]/g;
    
    s/\btext\((.+?),(.+?)\)/pack("C*", \@{\$context->{'inbuffer'}{'data'}}[$1..($1 + $2 - 1)])/gs; # text(offset, length), только в утилитах.
    
    s/\bchar_to_lower\((.+?)\)/\$chars[$1][0]/g;
    s/\bchar_to_digit\((.+?)\)/\$chars[$1][1]/g;

    #s/\bchar_is_dec\((.+?)\)/(\$chars[$1][2] & 1)/g;       
    #s/\bchar_is_hex\((.+?)\)/(\$chars[$1][2] & 2)/g;    
    s/\bchar_is_alpha\((.+?)\)/(\$chars[$1][2] & 4)/g;    
    s/\bchar_is_space\((.+?)\)/(\$chars[$1][2] & 8)/g;   
    s/\bchar_is\((.+?),(.+?)\)/(\$chars[$1][2] & ($2))/gs; # char_is(ch(n), flag)
    
    #----- Парсер --------------------------------------------------------------
    #---------------------------------------------------------------------------
    
    s/\battribute_contain\((.+?),(.+?),(.+?)\)/(exists(%{$1}{'attributes'}->{$2}) && lc(%{$1}{'attributes'}->{$2}{'value'}) eq $3)/g;
 
    s/\bbitset_test\((.+?),(.+?)\)/(\@{$1}[$2 >> 5] & 1 << ($2 & 31))/g; 

    s/\bsti_push\((.+?),(.+?)\)/push(\@{\%{$1}{'sti'}}, $2)/g;
    s/\bsti_pop\((.+?)\)/pop(\@{\%{$1}{'sti'}})/g;
    
    s/\bafe_contain\((.+?),(.+?)\)/($2 == \%{$1}{'afe'} || %{$2}{'afenext'} != 0)/g;
    s/\bsoe_contain\((.+?),(.+?)\)/($2 == \%{$1}{'soe'} || %{$2}{'soenext'} != 0)/g;
};

1;
