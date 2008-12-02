use Test::More qw/no_plan/;

use Util::Any qw/Scalar/;
no strict 'refs';

foreach (@Scalar::Util::EXPORT_OK) {
  ok( defined &{$_} , $_);
}

foreach (@Hash::Util::EXPORT_OK) {
  ok(! defined &{$_} , $_);
}

foreach (@List::Util::EXPORT_OK) {
  ok(! defined &{$_} , $_);
}
foreach (@List::MoreUtils::EXPORT_OK) {
  ok(! defined &{$_} , $_);
}

