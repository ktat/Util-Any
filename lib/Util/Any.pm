package Util::Any;

use ExportTo ();
use Carp ();
use warnings;
use strict;

our $Utils = {
              list   => [ qw/List::Util List::MoreUtils/ ],
              scalar => [ qw/Scalar::Util/ ],
              hash   => [ qw/Hash::Util/ ],
             };

sub import {
  my $pkg = shift;

  no strict 'refs';

  my $config = ${$pkg . '::Utils'};
  my $caller = (caller)[0];
  my %want;
  my %opt = (prefix => 0, module_prefix => 0);

  if (@_ > 1 and ref $_[-1] eq 'HASH') {
    %opt = (%opt, %{pop()});
  }

  if (@_) {
    if (ref $_[0] eq 'HASH') {
      my %_want = %{shift()};
      %want = map {lc($_) => $_want{$_}} keys %_want;
    } elsif (lc($_[0]) eq 'all') {
      @want{keys %$config} = ();
    } else {
      @want{map lc $_, @_} = ();
    }
  }

  no strict 'refs';

  foreach my $kind (keys %$config) {
    my ($prefix, $module_prefix) = ('','');

    if (exists $want{$kind}) {
      foreach my $class (@{$config->{$kind}}) {
        ($class, $module_prefix) = ref $class ? @$class : ($class, '');
        if ($opt{module_prefix} and $module_prefix) {
          $prefix = $module_prefix;
        } elsif ($opt{prefix}) {
          $prefix = lc($kind) . '_';
        }
        eval "require $class";
        unless ($@) {
          my @funcs = @{${class} . '::EXPORT_OK'};
          if (my $want_func = $want{$kind}) {
            my %w;
            @w{@$want_func} = ();
            @funcs = grep exists $w{$_}, @funcs;
          }
          if ($prefix) {
            ExportTo::export_to
                ($caller => {map {$prefix . $_ => $class . '::' . $_} @funcs});
          } else {
            ExportTo::export_to
                ($caller => [map $class . '::' . $_, @funcs]);
          }
        } else {
          Carp::carp $@;
        }
      }
    }
  }
}


=head1 NAME

Util::Any - Export any utilities and To create your own Util::Any

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    use Util::Any qw/list/;
    # you can import any functions of List::Util and List::MoreUtils

    print uniq qw/1, 0, 1, 2, 3, 3/;

If you want to choose functions

    use Util::Any {list => qw/uniq/};
    # you can import uniq function, not import other functions

    print uniq qw/1, 0, 1, 2, 3, 3/;

If you want to import All kind of utility functions

    use Util::Any qw/all/;

If you want to import functions with prefix(ex. list_, scalar_, hash_)

    use Util::Any qw/all/, {prefix => 1};
    use Util::Any qw/list/, {prefix => 1};
    use Util::Any {List => qw/uniq/}, {prefix => 1};
    
    print list_uniq qw/1, 0, 1, 2, 3, 3/;

=head1 DESCRIPTION

For the people who cannot remember uniq function is in whether List::Util or List::MoreUtils.

=head1 EXPORT

Functions which are exported by List::Util, List::MoreUtils, Hash::Util.

=head1 FUNCTIONS

no functions.

=head1 CREATE YOUR OWN Util::Any

Just inherit Util::Any and define $Utils hash ref as the following.

 package Util::Yours;
 
 use Clone qw/clone/;
 use base qw/Util::Any/;
 our $Utils = clone $Util::Any::Utils;
 push @{$Utils->{list}}, qw/Your::Favorite::List::Utils/;
 
 1;

In your code;

 use Util::Yours qw/list/;

=head1 PREFIX FOR EACH MODULE

If you want to import many modules and they have same function name.
You can specify prefix for each module like the following.

 use base qw/Util::Any/;
 
 our $Utils = {
      list => [['List::Util' => 'lu_'], ['List::MoreUtils' => 'lmu_']]
 };

In your code;

 use Util::Yours qw/list/, {module_prefix => 1};

=head1 AUTHOR

Ktat, C<< <ktat at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-util at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Util-Any>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Util::Any

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Util-Any>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Util-Any>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Util-Any>

=item * Search CPAN

L<http://search.cpan.org/dist/Util-Any>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2008 Ktat, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Util-Any
