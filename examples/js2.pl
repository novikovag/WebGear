use strict;

use WebGear::HTML::Console;
use WebGear::HTML::Parser;
use WebGear::SpiderMonkey;

my ($script, $jsruntime, $jscontext);

$jsruntime = js_initialize_runtime();
$jscontext = js_initialize_context($jsruntime);

$script = <<'SCRIPT';
    var e1 = document.createElement("div");
    var e2 = document.createElement("a");
    var e3 = document.createElement("b");
    
    e1.appendChild(e2);
    e2.appendChild(e3);
    
    console.tree(e1);
SCRIPT

js_evaluate($jscontext, $script, length $script);
js_destroy_context($jscontext);

js_destroy_runtime($jsruntime);

sub js_callback 
{
    my ($name) = shift;
    my ($error, $message, $index, $node, $target, $type);
 
    if ($name eq "js_reporter") {
        ($error, $message, $index) = @_;
        printf "%s\n", $error;
        printf "\t%s\n\t%*s\n", $message, $index, "^" if $message; 
    } elsif ($name eq "js_console_log") {
        $message = $_[0];
        printf "->%s\n", $message;
    } elsif ($name eq "js_console_tree") {
        $node = $_[0];
        console_print_tree($node);
    } elsif ($name eq "js_console_event") {
        ($target, $type) = @_;
        printf "EVENT -> target: %s, type: '%s'\n", $target->{'token.str'}, $type;
    }
}
