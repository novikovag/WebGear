use strict;

use WebGear::HTML::DOM;
use WebGear::HTML::Parser;
use WebGear::HTML::Console;

my ($FH, $filename, $data, $datalength, @data, $inbuffer, $document, $hcontext);

$filename = "html2.html";

open $FH, "<:raw", $filename or die $!;

$datalength = read $FH, $data, -s $filename;
@data       = unpack "C*", $data;

$inbuffer   = {
    'data'       => \@data,
    'datalength' => scalar @data,
    'index'      => 0
};

$document = node_create_document();
$hcontext = parser_initialize_context($inbuffer);
parser_parse($hcontext);

console_print_json_tree($hcontext->{'document'});
