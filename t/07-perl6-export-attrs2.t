use strict;

use lib qw(./lib ./t/lib);
use strict;
my $err;
BEGIN {
  eval "use UtilPerl6ExportAttrsBase qw/l2s :bar/;";
  $err = $@;
}

use Test::More qw/no_plan/;

SKIP: {
  skip $err if $err;
  ok(defined &first,  'defined first');
  ok(defined &min,    'defined min');
  ok(defined &minstr, 'defined minstr');
  ok(!defined &foo,   'not defined foo');
  ok(defined &bar,    'defined bar');

  is((first { defined $_} ("abc","def", "ghi")), "abc", "first");
  is(min(20, 50, 10), 10, "min");
  is(bar(), 'bar!', 'bar');
}
