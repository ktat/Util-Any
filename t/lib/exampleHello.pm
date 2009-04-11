package exampleHello;

use base qw/Exporter/;
use strict;

our @EXPORT_OK = qw/hello_name hello_where/;

sub hello_name {my %arg = @_; "hello, $arg{name}"}
sub hello_where {
  my %arg = @_;
  return "hello, $arg{where}";
}

1;
