use strict;

use WebGear::HTML::Console; 
use WebGear::HTML::Parser;

my ($html, @data, $context);

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

@data    = unpack "C*", $html;

$context = parser_initialize_context();
parser_parse($context, \@data, scalar @data);

# console_print_tree($context->{'document'});
console_print_tree($context->{'document'}, "s");
