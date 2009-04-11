package UtilExporter;

use strict;
use Clone qw/clone/;

use Util::Any -Exporter;

our @EXPORT = qw/hello/;
our @EXPORT_OK = qw/askme hello hi/;
our %EXPORT_TAGS = (
                    'greet' => [qw/hello hi/],
                    'uk'    => [qw/hello/],
                    'us'    => [qw/hi/],
                    'hello' => [qw/hello_name hello_where/],
                   );

our $Utils = clone $Util::Any::Utils;
$Utils->{l2s} = [
                 ['List::Util', '', [qw(first min minstr max maxstr sum)]],
                ];
$Utils->{-hello} = ['exampleHello'];

sub hello { "hello there" }
sub askme { "what you will" }
sub hi    { "hi there" }

1;
