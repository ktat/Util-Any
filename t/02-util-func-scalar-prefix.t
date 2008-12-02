use Test::More qw/no_plan/;

use Util::Any {Scalar => [qw/blessed weaken/]}, {prefix => 1};
no strict 'refs';

ok(defined &scalar_weaken , 'weaken');
ok(defined &scalar_blessed , 'blessed');
my $hoge = bless {};
ok(scalar_blessed $hoge, "blessed test");

foreach (grep {$_ ne 'weaken' and $_ ne 'blessed'} @Scalar::Util::EXPORT_OK) {
  ok(! defined &{'scalar_' . $_} , $_);
}

foreach (@Hash::Util::EXPORT_OK) {
  ok(! defined &{'hash_' . $_} , $_);
}

foreach (@List::Util::EXPORT_OK) {
  ok(! defined &{'list_' . $_} , $_);
}

foreach (@List::MoreUtils::EXPORT_OK) {
  ok(! defined &{'list_' . $_} , $_);
}
