use strict;

use WebGear::HTML::DOM;
use WebGear::HTML::Parser;
use WebGear::HTML::Console; 

my ($html, @data, $inbuffer, $document, $hcontext);

$html = <<'HTML';
<!DOCTYPE html>
<html>
<head>
    <title>Page Title</title>
</head>
<body>
    <h1>My First Heading</h1>
    <p>My first paragraph.</p>
</body>
</html>
HTML

@data     = unpack "C*", $html;

$inbuffer = {
    'data'       => \@data,
    'datalength' => scalar @data,
    'index'      => 0
};

$document = node_create_document();
$hcontext = parser_initialize_context($inbuffer, $document);
parser_parse($hcontext);

# console_print_tree($hcontext->{'document'});
console_print_tree($hcontext->{'document'}, "s");
