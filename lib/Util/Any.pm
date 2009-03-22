package Util::Any;

use ExportTo ();
use Carp ();
use warnings;
use List::MoreUtils qw/uniq/;
use strict;

our $Utils = {
              list   => [ qw/List::Util List::MoreUtils/ ],
              scalar => [ qw/Scalar::Util/ ],
              hash   => [ qw/Hash::Util/ ],
              debug  => [ ['Data::Dumper', '', ['Dumper']] ],
              string => [ qw/String::Util String::CamelCase/ ],
             };

sub import {
  my $pkg = shift;
  my $caller = (caller)[0];

  return $pkg->_base_import($caller, @_) if @_ and $_[0] =~/^-\w+$/;

  no strict 'refs';

  my $config = ${$pkg . '::Utils'};
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

  foreach my $kind (keys %$config) {
    my ($prefix, $module_prefix, $options) = ('', '', []);

    if (exists $want{$kind}) {
      foreach my $class (@{$config->{$kind}}) {
        ($class, $module_prefix, $options) = ref $class ? @$class : ($class, '', []);
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
          my $export_funcs = ref $options eq 'ARRAY' ? $options : $options->{-select};
          my (%funcs, %rename);
          no strict 'refs';
          @funcs{@{$class . '::EXPORT_OK'}, @{$class . '::EXPORT'}} = ();
          my @funcs = grep defined &{$class . '::' . $_}, keys %funcs;
          if (my $want_func = $want{$kind}) {
            my %w;
            @w{@$want_func} = ();
            @funcs = grep exists $w{$_}, @funcs;
          } elsif (@{$export_funcs || []}) {
            @funcs = grep defined &{$class . '::' . $_}, @$export_funcs;
          }
          if (ref $options eq 'HASH') {
            if (exists $options->{-except}) {
              Carp::croak "cannot use -select & -except in same time." if @{$export_funcs || []};
              my %except;
              @except{@{$options->{-except}}} = ();
              @funcs = grep !exists $except{$_}, @funcs;
            }
            foreach my $o (grep !/^-/, keys %$options) {
              if (defined &{$class . '::' . $o}) {
                push @funcs , $o;
                $rename{$o} = $options->{$o};
              }
            }
          }
          ExportTo::export_to($caller => ($prefix or %rename)
                              ? {map {$prefix . ($rename{$_} || $_) => $class . '::' . $_} uniq @funcs}
                              : [map $class . '::' . $_, uniq @funcs]);
        } elsif(defined $opt{debug}) {
          $opt{debug} == 2 ? Carp::croak $evalerror : Carp::carp $evalerror;
        }
      }
    }
  }
  my $import_module = $pkg->_use_import_module;
  if ($import_module) {
    no strict 'refs';
    no warnings;
    my $pkg_utils = ${$pkg . '::Utils'};
    my @arg = defined $pkg_utils ? (grep !exists $pkg_utils->{$_}, @_)
                                 : (grep !exists $Utils->{$_}, @_);
    if ((@_ and @arg) or !@_) {
      if ($import_module eq 'Perl6::Export::Attrs') {
        eval "package $caller; $pkg" . '->Perl6::Export::Attrs::_generic_import(@arg);';
      } elsif ($import_module eq 'Exporter::Simple') {
        eval "package $caller; $pkg" . '->Exporter::Simple::import(@arg);';
      } elsif ($import_module eq 'Exporter') {
        eval "package $caller; $pkg" . '->Exporter::import(@arg);';
      }
    }
  }
}

sub _base_import {
  my ($pkg, $caller, @flgs) = @_;
  {
    no strict 'refs';
    push @{"${caller}::ISA"}, __PACKAGE__;
  }
  my @unknown;

  while (my $flg = lc shift @flgs) {
    no strict 'refs';
    if ($flg eq '-perl6exportattrs') {
      eval "use Perl6::Export::Attrs ();";
      *{$caller . '::MODIFY_CODE_ATTRIBUTES'} = \&Perl6::Export::Attrs::_generic_MCA;
      *{$caller . '::_use_import_module'} = sub { 'Perl6::Export::Attrs' };
    } elsif ($flg eq '-exportersimple') {
      eval "use Exporter::Simple ();";
      *{$caller . '::_use_import_module'} = sub { 'Exporter::Simple' };
    } elsif ($flg eq '-exporter') {
      use Exporter ();
      push @{"${caller}::ISA"}, 'Exporter';
      *{$caller . '::_use_import_module'} = sub { 'Exporter' };
    } elsif ($flg eq '-base') {
      # nothing to do
    } else {
      push @unknown, $flg;
    }
  }
  Carp::croak "cannot understand the option: @unknown" if @unknown;
}

sub _use_import_module { 0 }

=head1 NAME

Util::Any - Export any utilities and To create your own Util::Any

=cut

our $VERSION = '0.06';

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

We, Perl users, have to memorize modules name and their functions name.
Using this module, you don't need to memorize modules name,
only memorize kinds of modules and functions name.

And this module allows you to create your own utility module, easily.
You can create your own module and use this in the same way as Util::Any like the following.

 use YourUtil qw/list/;

see C<CREATE YOUR OWN Util::Any>, in detail.

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
Note that these modules and version are on my environment(Perl 5.8.4).
So, it must be diffrent on your environment.

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

=head1 CREATE YOUR OWN Util::Any

Just inherit Util::Any and define $Utils hash ref as the following.

 package Util::Yours;
 
 use Clone qw/clone/;
 use Util::Any -Base; # or use base qw/Util::Any/;
 our $Utils = clone $Util::Any::Utils;
 push @{$Utils->{list}}, qw/Your::Favorite::List::Utils/;
 
 1;

In your code;

 use Util::Yours qw/list/;

=head2 $Utils STRUCTURE

=head3 overview

 $Utils => {
    # simply put module names
    kind1 => [qw/Module1 Module2 ..../],
    # Module name and its prefix
    kind2 => [ [Module1 => 'module_prefix'], ... ],
    # limit functions to be exported
    kind3 => [ [Module1, 'module_prefix', [qw/func1 func2/] ], ... ],
    # as same as above except not specify modul prefix
    kind4 => [ [Module1, '', [qw/func1 func2/] ], ... ],
 };

=head3 Key must be lower character.

 NG $Utils = { LIST => [qw/List::Util/]};
 OK $Utils = { list => [qw/List::Util/]};

=head3 C<all> cannot be used for key.

 NG $Utils = { all => [qw/List::Util/]};

=head3 Value is array ref which contained scalar or array ref.

Scalar is module name. Array ref is module name and its prefix.

 $Utils = { list => ['List::Utils'] };
 $Utils = { list => [['List::Utils', 'prefix_']] };

see L<PREFIX FOR EACH MODULE>

=head2 PREFIX FOR EACH MODULE

If you want to import many modules and they have same function name.
You can specify prefix for each module like the following.

 use base qw/Util::Any/;
 
 our $Utils = {
      list => [['List::Util' => 'lu_'], ['List::MoreUtils' => 'lmu_']]
 };

In your code;

 use Util::Yours qw/list/, {module_prefix => 1};

=head2 OTHER WAY TO EXPORT FUNCTIONS

=head2 SELECT FUNCTIONS

Util::Any auomaticaly export functions from modules' @EXPORT and @EXPORT_OK.
In some cases, it is not good idea like Data::Dumper's Dumper and DumperX.

So you can limit functions to be exported.

 our $Utils = {
      debug => [
                ['Data::Dumper', '',
                ['Dumper']], # only Dumper method is exported.
               ],
 };

or

 our $Utils = {
      debug => [
                ['Data::Dumper', '',
                 { -select => ['Dumper'] }, # only Dumper method is exported.
                ]
               ],
 };


=head2 SELECT FUNCTIONS EXCEPT

Inverse of -select option. Cannot use this option with -select.

 our $Utils = {
      debug => [
                ['Data::Dumper', '',
                 { -except => ['DumperX'] }, # export functions except DumperX
                ]
               ],
 };

=head2 RENAME FUNCTIONS

To rename function name. Using this option with -select or -exception,
this definition is prior to them.

In the following example, 'min' is not in -select list, but can be exported.

 our $Utils = {
      list  => [
                 [
                  'List::Util', '',
                  {
                   'first' => 'list_first', # first as list_first
                   'sum'   => 'lsum',       # sum   as lsum
                   'min'   => 'lmin',       # min   as lmin
                   -select => ['first', 'sum', 'shuffle'],
                  }
                 ]
                ],
  };


=head1 WORKING WITH EXPORTER-LIKE MODULES

CPAN has some modules to export functions.
Util::Any can work with some of such modules, L<Exporter>, L<Exporter::Simple> and L<Perl6::Export::Attrs>.
If you want to use other modules, please inform me or implement import method by yourself.

If you want to use module mentioned above, you have to change the way to inherit these modules.

=head2 ALTERNATIVE INHERITING

Normaly, you use;

 use Util::Any -Base; # or "use base qw/Util::Any/;"

But, if you want to use L<Exporter>, L<Exporter::Simple> or L<Perl6::Export::Attrs>.
write as the following, instead.

 # if you want to use Exporter
 use Util::Any -Exporter;
 # if you want to use Exporter::Simple
 use Util::Any -ExporterSimple;
 # if you want to use Perl6::Export::Attrs
 use Util::Any -Perl6ExportAttrs;

That's all.
Note that don't use base the above modules in your utility module.

=head3 EXAMPLE to USE Perl6::Export::Attrs in YOUR OWN UTIL MODULE

 package Util::Yours;
 
 use Clone qw/clone/;
 use Util::Any -Perl6ExportAttrs;
 our $Utils = clone $Util::Any::Utils;
 push @{$Utils->{list}}, qw/Your::Favorite::List::Utils/;
 
 sub foo :Export(:DEFAULT) {
   return "foo!";
 }
 
 sub bar :Export(:bar) {
   return "bar!";
 }
 
 1;

=head2 IMPLEMENT IMPORT by YOURSELF

You can write your own import method and BEGIN block like the following.
Instead of using "use Util::Any -Perl6ExportAttrs".

 package UtilPerl6ExportAttr;
 
 use strict;
 use base qw/Util::Any/;
 use Clone qw/clone/;
 
 BEGIN {
   use Perl6::Export::Attrs ();
   no strict 'refs';
   *{__PACKAGE__ . '::MODIFY_CODE_ATTRIBUTES'} = \&Perl6::Export::Attrs::_generic_MCA;
 }
 
 our $Utils = clone $Util::Any::Utils;
 $Utils->{your_list} = [
                  ['List::Util', '', [qw(first min sum)]],
                 ];
 
 sub import {
   my $pkg = shift;
   my $caller = (caller)[0];
 
   no strict 'refs';
   eval "package $caller; $pkg" . '->Util::Any::import(@_);';
   my @arg = grep !exists $Utils->{$_}, @_;
   if ((@_ and @arg) or !@_) {
     eval "package $caller; $pkg" . '->Perl6::Export::Attrs::_generic_import(@arg)';
   }
   return;
 }
 
 sub foo :Export(:DEFAULT) {
   return "foo!";
 }
 
 1;

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

=head1 REPOSITORY

  svn co http://svn.coderepos.org/share/lang/perl/Util-Any/trunk Util-Any

Subversion repository of Util::Any is hosted at http://coderepos.org/share/.
patches and collaborators are welcome.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2008 Ktat, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Util-Any
