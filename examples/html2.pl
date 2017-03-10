use strict;

use WebGear::HTML::Console; 
use WebGear::HTML::Parser;

my ($FH, $filename, $data, $datalength, @data, $context);

$filename = "html2.html";

open $FH, "<:raw", $filename or die $!;

$datalength = read $FH, $data, -s $filename;
@data       = unpack "C*", $data;

$context = parser_initialize_context();
parser_parse($context, \@data, scalar @data);

console_print_json_tree($context->{'document'});
