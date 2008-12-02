use Test::More qw/no_plan/;

use Util::Any qw/All/;
no strict 'refs';

foreach (@List::Util::EXPORT_OK) {
  ok(defined &{$_} , $_);
}
foreach (@List::MoreUtils::EXPORT_OK) {
  ok(defined &{$_} , $_);
}

foreach (@Scalar::Util::EXPORT_OK) {
  ok(defined &{$_} , $_);
}

foreach (@Hash::Util::EXPORT_OK) {
  ok(defined &{$_} , $_);
}

