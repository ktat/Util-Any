use strict;

use lib qw(./lib ./t/lib);

my $err;
use UtilExporter
  -hello => [hello_name  => {-as => 'hello_ktat', name => 'ktat'},
             hello_where => {-as => 'hello_japan', where => 'japan'},
             hello_where => {-as => 'hello_japan', in => 'japan', where => 'osaka'}],
 'askme';


use strict;
use Test::More qw/no_plan/;

ok(defined &hello_ktat,  'defined hello_ktat');
ok(defined &hello_japan, 'defined hello_japan');
ok(defined &askme,  'defined askme');

is(hello_ktat(), 'hello, ktat'  , 'hello, ktat');
is(hello_japan(), 'hello, japan', 'hello, japan');
is(hello_japan(where => "Osaka"), 'hello, Osaka', 'override where');
