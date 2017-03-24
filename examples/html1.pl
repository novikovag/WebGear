use strict;

use WebGear::HTML::Console; 
use WebGear::HTML::Parser;

my ($html, @data, $inbuffer, $context);

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

$context = parser_initialize_context($inbuffer);
parser_parse($context);

# console_print_tree($context->{'document'});
console_print_tree($context->{'document'}, "s");
