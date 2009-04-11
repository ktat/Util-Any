use strict;

use lib qw(./lib ./t/lib);

my $err;
BEGIN {
  eval "use UtilSubExporter 'all'";
  $err = $@;
}

use strict;
use Test::More qw/no_plan/;

SKIP: {
skip $err if $err;

ok(defined &first,  'defined first');
ok(defined &min,    'defined min');
ok(defined &minstr, 'defined minstr');
ok(!defined &hello,       'not defined hello');
ok(!defined &hi,          'not defined hi');
ok(!defined &askme,       'not defined askme');

is((first {$_ >= 4} (2,10,4,3,5)), 10, 'list first');

}
