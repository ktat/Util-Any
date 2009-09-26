use Test::More qw/no_plan/;

use lib qw(./lib t/lib);

package AAA;

use UtilPluggable -pluggable;
use Test::More;

ok(defined &test);
ok(defined &test2);
ok(defined &camelize);
ok(!defined &test3);

package BBB;

use UtilPluggable -pluggable2;
use Test::More;

ok(!defined &test);
ok(!defined &test2);
ok(!defined &camelize);
ok(defined &test3);

package CCC;

use Test::More;
use UtilPluggable -pluggable, -pluggable2;

ok(defined &test);
ok(defined &test2);
ok(defined &camelize);
ok(defined &test3);

package DDD;

use Test::More;
use UtilPluggable -all;

ok(defined &test);
ok(defined &test2);
ok(defined &camelize);
ok(defined &test3);
