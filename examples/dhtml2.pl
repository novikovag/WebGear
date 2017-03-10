use strict;

use WebGear::HTML::Console;
use WebGear::HTML::Parser;
use WebGear::SpiderMonkey;

my ($FH, $filename, $data, $datalength, @data, $plcontext, $jsruntime, $jscontext);

$filename = "dhtml2.html";

open $FH, "<:raw", $filename or die $!;

$datalength = read $FH, $data, -s $filename;
@data       = unpack "C*", $data;

$plcontext  = parser_initialize_context();

$jsruntime  = js_initialize_runtime();
$jscontext  = js_initialize_context($jsruntime, $plcontext->{'document'});

parser_parse($plcontext, \@data, scalar @data, $jscontext, \&js_evaluate);

console_print_tree($plcontext->{'document'}, "s");

js_destroy_context($jscontext);
js_destroy_runtime($jsruntime);

sub WebGear::HTML::Parser::js_callback 
{
    my ($name) = shift;
    my ($error, $message, $index, $node, $target, $type);

    if ($name eq "js_reporter") {
        ($error, $message, $index) = @_;
        printf "%s\n", $error;
        printf "\t%s\n\t%*s\n", $message, $index, "^" if $message; 
    } elsif ($name eq "js_console_log") {
        $message = $_[0];
        printf "%s\n", $message;
    } elsif ($name eq "js_console_tree") {
        $node = $_[0];
        console_print_tree($node);
    } elsif ($name eq "js_console_event") {
        ($target, $type) = @_;
        printf "EVENT -> target: %s, type: '%s'\n", $target->{'token.str'}, $type;
    }
}
