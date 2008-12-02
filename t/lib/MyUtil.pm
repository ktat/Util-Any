package MyUtil;

BEGIN {
  use base qw/Util::Any/;
  %Util::Any::Utils =
    (
     List => [qw/List::Util/],
    );
}

1;
