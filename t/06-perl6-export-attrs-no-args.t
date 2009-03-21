use strict;

use lib qw(./lib ./t/lib);
use strict;
my $err;
BEGIN {
  eval "use UtilPerl6ExportAttrs";
  $err = $@;
}

use Test::More qw/no_plan/;

SKIP: {
  skip $err if $err;
  ok(!defined &first,  'not defined first');
  ok(!defined &min,    'not defined min');
  ok(!defined &minstr, 'not defined minstr');
  ok(defined &foo,     'defined foo');
  ok(!defined &bar,    'not defined bar');

  is(foo(), "foo!", 'foo');
}
