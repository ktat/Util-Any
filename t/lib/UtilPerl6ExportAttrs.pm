package UtilPerl6ExportAttrs;

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
    eval {
    eval <<_CODE;
      use Util::Any -Perl6ExportAttrs;
      sub foo :Export(:DEFAULT) {
        return "foo!";
      }

      sub bar :Export(:bar) {
        return "bar!";
      }
_CODE
    };
  }
}

our $Utils = clone $Util::Any::Utils;
$Utils->{l2s} = [
                 ['List::Util', '', [qw(first min minstr max maxstr sum)]],
                ];

## sub import {
##   my $pkg = shift;
##   my $caller = (caller)[0];
## 
##   no strict 'refs';
##   eval "package $caller; $pkg" . '->Util::Any::import(@_);';
##   my @arg = grep !exists $Utils->{$_}, @_;
##   if (@_ and @arg) {
##     eval "package $caller; $pkg" . '->Perl6::Export::Attrs::_generic_import(@arg)';
##   } elsif (!@_) {
##     eval "package $caller; $pkg" . '->Perl6::Export::Attrs::_generic_import';
##   }
##   return;
## }

1;
