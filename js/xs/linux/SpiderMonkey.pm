package WebGear::SpiderMonkey;
use strict;

use Exporter qw(import);
our @EXPORT = qw(
    js_initialize_runtime
    js_initialize_context
    js_destroy_runtime
    js_destroy_context
    js_evaluate
);

our $VERSION = '1.00';

require XSLoader;
XSLoader::load('WebGear::SpiderMonkey', $VERSION);

1;

