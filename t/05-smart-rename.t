use Test::More 'no_plan';
use lib qw(./lib t/lib);
use SmartRename -utf8, {smart_rename => 1};

ok(!defined(&utf8_is_utf8));
ok(!defined(&utf8_utf8_upgrade));
ok(defined(&is_utf8));
ok(defined(&utf8_upgrade));
ok(defined(&utf8_downgrade));

