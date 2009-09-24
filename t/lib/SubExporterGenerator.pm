package SubExporterGenerator;

use strict;
use Util::Any -Base;

our $Utils =
  {
   -test => [
             [
              'List::MoreUtils', '',
              ['uniq'],
             ],
             [
             'List::Util', '',
             {
              -select => ['shuffle'],
              min => \&build_min_reformatter,
              max => \&build_max_reformatter,
             }
            ],
            ]
  };

sub build_min_reformatter {
  my ($pkg, $class, $name, @option) = @_;
  no strict 'refs';
  my $code = do { no strict 'refs'; \&{$class . '::' . $name}};
  sub {
    my @args = @_;
    $code->(@args, ($option[0]->{under} || ()));
  }
}

sub build_max_reformatter {
  my ($pkg, $class, $name, @option) = @_;
  my $code = do { no strict 'refs'; \&{$class . '::' . $name}};
  sub {
    my @args = @_;
    $code->(@args, ($option[0]->{upper} || ()));
  }
}

1;
