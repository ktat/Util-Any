use strict;

use lib qw(./lib ./t/lib);
use strict;
my $err;

BEGIN {
  eval "use UtilPerl6ExportAttrs qw/:All/";
  $err = $@;
}

use Test::More qw/no_plan/;

SKIP: {
  skip $err if $err;
  ok(defined &first,  'defined first');
  ok(defined &min,    'defined min');
  ok(defined &minstr, 'defined minstr');
  ok(defined &foo,    'defined foo');
  ok(defined &bar,    'defined bar');

  is(foo(), "foo!", 'foo');
}
