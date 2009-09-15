package main;

use strict;
use lib qw(lib t/lib);
use SubExporterGenerator -test => {min => {-as => "min_under_20", under => 20},
                                   max => {-as => "max_upper_100", upper => 100}};
use Test::More 'no_plan';

is(min_under_20(100,25,30), 20);
is(min_under_20(100,10,30), 10);
is(max_upper_100(80,25,30), 100);
is(max_upper_100(130,10,30), 130);
