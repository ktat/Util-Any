package Util::Any;

use ExportTo ();
use Carp ();
use warnings;
use strict;

our $Utils = {
              list   => [ qw/List::Util List::MoreUtils/ ],
              scalar => [ qw/Scalar::Util/ ],
              hash   => [ qw/Hash::Util/ ],
              debug  => [ qw/Data::Dumper/],
              string => [ qw/String::Util String::CamelCase/],
             };

sub import {
  my $pkg = shift;

  no strict 'refs';

  my $config = ${$pkg . '::Utils'};
  my $caller = (caller)[0];
  my %want;
  my %opt = (prefix => 0, module_prefix => 0, debug => 0);

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
        my $evalerror;
        {
          local $@;
          eval "require $class";
          $evalerror = $@;
        };
        unless ($evalerror) {
          my %funcs;
          @funcs{@{$class . '::EXPORT_OK'}, @{$class . '::EXPORT'}} = ();
          my @funcs = grep defined &{$class . '::' . $_}, keys %funcs;
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
          if ($opt{debug} == 2) {
            Carp::croak $evalerror;
          } elsif($opt{debug}) {
            Carp::carp $evalerror;
          }
        }
      }
    }
  }
}

=head1 NAME

Util::Any - Export any utilities and To create your own Util::Any

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

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
    
    my $o = bless {};
    my %hash = (a => 1, b => 2);
    
    # from Scalar::Util
    blessed $o;
    
    # from Hash::Util
    lock_keys %hash;

If you want to import functions with prefix(ex. list_, scalar_, hash_)

    use Util::Any qw/all/, {prefix => 1};
    use Util::Any qw/list/, {prefix => 1};
    use Util::Any {List => qw/uniq/}, {prefix => 1};
    
    print list_uniq qw/1, 0, 1, 2, 3, 3/;

=head1 DESCRIPTION

For the people like the man who cannot remember C<uniq> function is in whether List::Util or List::MoreUtils.
And for the newbie who don't know where useful utilities is.

Perl has many modules and they have many utility functions.
For example, List::Util, List::MoreUtils, Scalar::Util, Hash::Util,
String::Util, String::CamelCase, Data::Dumper etc.

We, Perl users, have to memorize module name and their function name.
Using this module, you don't need to memorize module name,
only memorize kind of modules and function name.

And this module allow you to create your own utility module, easily.
You can create your own module and use this in the same way as Util::Any like the following.

 use YourUtil qw/list/;

see C<CREATE YOUR OWN Util::Any>.

=head1 HOW TO USE

=head2 use Util::Any (KIND)

 use Util::Any qw/list hash/;

Give list of kinds of modules. All functions in moduls are exporeted.

=head2  use Util::Any {KIND => [FUNCTIONS], ...};

 use Util::Any {list => ['uniq'], hash => ['lock_keys']};

Give hash ref whose key is kind and value is function names.
Selected functions are exported.

=head2  use Util::Any ..., {OPTION => VALUE};

Util::Any can take last argument as option, which should be hash ref.

=over 4

=item prefix => 1

add kind prefix to function name.

 use Util::Any qw/list/, {prefix => 1};
 
 list_uniq(1,2,3,4,5); # it is List::More::Utils's uniq function

=item module_prefix => 1

see L<PREFIX FOR EACH MODULE>.
Uti::Any itself doesn't have such a definition.

=item debug => 1/2

Util::Any doesn't say anything when loading module fails.
If you pass debug value, warn or die.

 use Util::Any qw/list/, {debug => 1}; # warn
 use Util::Any qw/list/, {debug => 2}; # die

=back

=head1 EXPORT

Kinds of functions and list of exported functions are below.
Note that these modules and version are in my environment(Perl 5.8.4).
So, it must be diffrent in your environment.

=head2 scalar

from Scalar::Util (1.19)

 blessed
 dualvar
 isvstring
 isweak
 looks_like_number
 openhandle
 readonly
 refaddr
 reftype
 set_prototype
 tainted
 weaken

=head2 hash

from Hash::Util (0.05)

 hash_seed
 lock_hash
 lock_keys
 lock_value
 unlock_hash
 unlock_keys
 unlock_value

=head2 list

from List::Util (1.19)

 first
 max
 maxstr
 min
 minstr
 reduce
 shuffle
 sum

from List::MoreUtils (0.21)

 after
 after_incl
 all
 any
 apply
 before
 before_incl
 each_array
 each_arrayref
 false
 first_index
 first_value
 firstidx
 firstval
 indexes
 insert_after
 insert_after_string
 last_index
 last_value
 lastidx
 lastval
 mesh
 minmax
 natatime
 none
 notall
 pairwise
 part
 true
 uniq
 zip

=head2 string

from String::Util (0.11)

 crunch
 define
 equndef
 fullchomp
 hascontent
 htmlesc
 neundef
 nospace
 randcrypt
 randword
 trim
 unquote

from String::CamelCase (0.01)

 camelize
 decamelize
 wordsplit

=head2 debug

from Data::Dumper (2.121)

 Dumper
 DumperX

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

=head2 $Utils STRUCTURE

Key must be lower character.

 NG $Utils = { LIST => [qw/List::Util/]};
 OK $Utils = { list => [qw/List::Util/]};

C<all> cannot be used for key.

 NG $Utils = { all => [qw/List::Util/]};

Value is array ref which contained scalar or array ref.
Scalar is module name. Array ref is module name and its prefix.

 $Utils = { list => ['List::Utils'] };
 $Utils = { list => [['List::Utils', 'prefix_']] };

see L<PREFIX FOR EACH MODULE>

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
C<bug-util-any at rt.cpan.org>, or through the web interface at
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
