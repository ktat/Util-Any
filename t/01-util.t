use Test::More qw/no_plan/;
use Util::Any ();
use strict;

require Cwd;
my @cwd_funcs = qw/cwd getcwd fastcwd fastgetcwd chdir abs_path fast_abs_path realpath fast_realpath/;
push @cwd_funcs, qw(getdcwd) if $^O eq 'MSWin32';


@cwd_funcs = sort @cwd_funcs;
my @funcs = sort @{Util::Any::_all_funcs_in_class('Cwd')};
is_deeply(\@funcs, \@cwd_funcs);

