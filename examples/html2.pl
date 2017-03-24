use strict;

use WebGear::HTML::Console; 
use WebGear::HTML::Parser;

my ($FH, $filename, $data, $datalength, @data, $inbuffer, $context);

$filename = "html2.html";

open $FH, "<:raw", $filename or die $!;

$datalength = read $FH, $data, -s $filename;
@data       = unpack "C*", $data;

$inbuffer   = {
    'data'       => \@data,
    'datalength' => scalar @data,
    'index'      => 0
};

$context = parser_initialize_context($inbuffer);
parser_parse($context);

console_print_json_tree($context->{'document'});
