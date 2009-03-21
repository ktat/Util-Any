package UtilPerl6ExportAttrsBase;

use strict;
use Clone qw/clone/;
BEGIN {
  my $err;
  {
    local $@;
    eval "use Perl6::Export::Attrs ()";
    $err = $@;
  }
  if ($err) {
    die $err;
  } else {
    use Util::Any -Perl6ExportAttrs;
    eval <<_CODE;
      sub foo :Export(:DEFAULT) {
        return "foo!";
      }

      sub bar :Export(:bar) {
        return "bar!";
      }
_CODE
  }
}

our $Utils = clone $Util::Any::Utils;
$Utils->{l2s} = [
                 ['List::Util', '', [qw(first min minstr max maxstr sum)]],
                ];

1;
