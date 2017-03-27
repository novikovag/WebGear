use strict;

use WebGear::HTML::Parser;
use WebGear::HTML::DOM;
use WebGear::HTML::Console;
use WebGear::SpiderMonkey;

my ($FH, $filename, $data, $datalength, @data, $inbuffer, $document,$jruntime, $jcontext,  $plcontext);

$filename = "dhtml2.html";

open $FH, "<:raw", $filename or die $!;

$datalength = read $FH, $data, -s $filename;
@data       = unpack "C*", $data;

$inbuffer = {
    'data'       => \@data,
    'datalength' => $datalength,
    'index'      => 0
};
   
$document  = node_create_document();    
   
$jruntime = js_initialize_runtime();
$jcontext = js_initialize_context($jruntime, $inbuffer, $document);
   
$plcontext = parser_initialize_context($inbuffer, $document, $jcontext);

parser_parse($plcontext);

console_print_tree($plcontext->{'document'}, "s");

js_destroy_context($jcontext);
js_destroy_runtime($jruntime);

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
