package Util::Any;

use ExportTo ();
use warnings;
use strict;

our %Utils = (
              List   => [ qw/List::Util List::MoreUtils/ ],
              Scalar => [ qw/Scalar::Util/ ],
              Hash   => [ qw/Hash::Util/ ],
             );

sub import {
  my $class = shift;
  my $caller = (caller)[0];
  my %want;
  my %opt = (prefix => 0);

  if (@_ > 1 and ref $_[-1] eq 'HASH') {
    %opt = (%opt, %{pop()});
  }

  if (@_) {
    if (ref $_[0] eq 'HASH') {
      %want = %{shift()};
    } elsif (lc($_[0]) eq 'all') {
      @want{keys %Utils} = ();
    } else {
      @want{@_} = ();
    }
  }

  no strict 'refs';

  foreach my $kind (keys %Utils) {
    my $prefix = lc($kind) . '_';
    if (exists $want{$kind}) {
      foreach my $class (@{$Utils{$kind}}) {
        eval "require $class";
        unless ($@) {
          my @funcs = @{${class} . '::EXPORT_OK'};
          unless (my $want_func = $want{$kind}) {
            if ($opt{prefix}) {
              ExportTo::export_to
                  ($caller => {map {$prefix . $_ => $class . '::' . $_} @funcs});
            } else {
              ExportTo::export_to
                  ($caller => [map $class . '::' . $_, @funcs]);
            }
          } else {
            my %w;
            @w{@$want_func} = ();
            if ($opt{prefix}) {
              ExportTo::export_to
                  ($caller => {map {$prefix . $_ => $class . '::' . $_} grep exists $w{$_}, @funcs});
            } else {
              ExportTo::export_to
                  ($caller => [map $class . '::' . $_, grep exists $w{$_}, @funcs]);
            }
          }
        }
      }
    }
  }
}


=head1 NAME

Util::Any - Export any utilities and To create your own Util::Any

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Util::Any qw/List/;
    # you can import any functions of List::Util and List::MoreUtils

    print uniq qw/1, 0, 1, 2, 3, 3/;

If you want to choose functions

    use Util::Any {List => qw/uniq/};
    # you can import uniq function, not import other functions

    print uniq qw/1, 0, 1, 2, 3, 3/;

If you want to import All kind of utility functions

    use Util::Any qw/All/;

If you want to import functions with prefix(ex. list_, scalar_, hash_)

    use Util::Any qw/All/, {prefix => 1};
    use Util::Any qw/List/, {prefix => 1};
    use Util::Any {List => qw/uniq/}, {prefix => 1};

=head1 DESCRIPTION

For the people who cannot remember uniq function is in whether List::Util or List::MoreUtils.

=head1 EXPORT

Functions which are exported by List::Util, List::MoreUtils, Hash::Util.

=head1 FUNCTIONS

no functions.

=head1 CREATE YOUR OWN Util::Any

 package Util::Yours;
 
 BEGIN {
  use base qw/Util::Any/;
  push @{$Util::Any::Utils{List}}, qw/Your::Favolite::List::Utils/;
 }
 
 1;

In your code.

 use Util::Yours qw/List/;

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
