package Util::Any;

use ExportTo ();
use Clone ();
use Carp ();
use warnings;
use List::MoreUtils ();
use strict;

our $Utils = {
              list   => [ qw/List::Util List::MoreUtils/ ],
              scalar => [ qw/Scalar::Util/ ],
              hash   => [ qw/Hash::Util/ ],
              debug  => [ ['Data::Dumper', '', ['Dumper']] ],
              string => [ qw/String::Util String::CamelCase/ ],
             };

# I'll delete no dash group in the above, in future.
$Utils->{'-' . $_} = $Utils->{$_} foreach keys %$Utils;

our $SubExporterImport = 'do_import';

sub import {
  my ($pkg, $caller) = (shift, (caller)[0]);
  return $pkg->_base_import($caller, @_) if @_ and $_[0] =~/^-[A-Z]\w+$/o;

  my %opt = (prefix => 0, module_prefix => 0, debug => 0, smart_rename => 0);
  if (@_ > 1 and ref $_[-1] eq 'HASH') {
    @opt{qw/prefix module_prefix debug smart_rename/} = (delete @{$_[-1]}{qw/prefix module_prefix debug smart_rename/});
    pop @_ unless %{$_[-1]};
  }
  @_ = %{$_[0]} if @_ == 1 and ref $_[0] eq 'HASH';

  my $config = Clone::clone(do { no strict 'refs'; ${$pkg . '::Utils'} });
  my ($arg, $want) = $pkg->_arrange_args(\@_, $config, $caller);
  foreach my $kind (keys %$want) {
    my ($prefix, $module_prefix, $options) = ('', '', []);
    Carp::croak "$pkg doesn't have such kind of functions : $kind" unless exists $config->{$kind};
    my ($funcs, $local_definition, $kind_prefix) = $pkg->_func_definitions($kind, $want->{$kind});

    foreach my $class (@{$config->{$kind}}) { # $class is class name or array ref
      # use Tie::Trace 'watch';
      # watch my @funcs;
      my %want_funcs;
      @want_funcs{@{$funcs->{$kind} || []}} = ();
      ($class, $module_prefix, $options) = @$class if ref $class;
      my $k = lc(join "", $kind =~m{(\w+)}go);
      $prefix = $kind_prefix                             ? $kind_prefix   :
                ($opt{module_prefix} and $module_prefix) ? $module_prefix :
                 $opt{prefix}                            ? lc($k) . '_'   :
                 $opt{smart_rename}                      ? $pkg->_create_smart_rename($k) : '';

      my $evalerror = '';
      if ($evalerror = do { local $@; eval {my $path = $class; $path =~s{::}{/}go; require $path. ".pm"; $evalerror = $@ }; $@}) {
      # if ($evalerror = do { local $@; eval "require $class";  $evalerror = $@ }) {
        $opt{debug} == 2 ? Carp::croak $evalerror : Carp::carp $evalerror;
      }
      my @funcs;
      my (%rename, %exported);
      if (ref $options eq 'HASH') {
        @funcs = @{$options->{-select}} if exists $options->{-select};
        if (exists $options->{-except}) {
          Carp::croak "cannot use -select & -except in same time." if exists $options->{select};
          my %except;
          @except{@{$options->{-except}}} = ();
          @funcs = grep !exists $except{$_}, @{_all_funcs_in_class($class)};
        } elsif (not @funcs) {
          @funcs = @{_all_funcs_in_class($class)};
        }
        my %tmp;
        @tmp{%want_funcs ? keys %want_funcs : grep(!/^-/, keys %$options)} = ();
        foreach my $o (keys %tmp) {
          next if not defined $options->{$o};
          if (ref $options->{$o} eq 'CODE') {
            my $gen = $options->{$o};
            if (%$local_definition) {
              foreach my $def (@{$local_definition->{$o}}) {
                my %arg;
                $arg{$_} = $def->{$_}  for grep !/^-/, keys %$def;
                ExportTo::export_to($caller => {(delete $def->{-as} || $o) => $gen->($pkg, $class, $o, \%arg)});
              }
            } else {
              ExportTo::export_to($caller => {$o => $gen->($pkg, $class, $o, {})});
            }
            $exported{$o} = undef;
            delete $want_funcs{$o};
          } elsif (defined &{$class . '::' . $o}) {
            push @funcs , $o;
            $rename{$o} = $options->{$o};
          }
        }
      } elsif(ref $options eq 'ARRAY') {
        push @funcs, @$options;
      } else {
        @funcs = @{_all_funcs_in_class($class)};
      }
      @funcs = grep !exists $exported{$_}, @funcs;
      $pkg->_do_export($caller, $class, \@funcs, \%want_funcs, $local_definition, \%rename, $prefix, $kind_prefix);
    }
  }
}

sub _create_smart_rename {
  my ($pkg, $kind) = @_;
  return sub {
    my $str = shift;
    my $prefix = '';
    if ($str =~s{^(is_|has_|enable_|disable_|isnt_|have_|set_)}{}) {
      $prefix = $1;
    }
    if ($str !~ m{^$kind} and $str !~ m{$kind$}) {
      return $prefix . $kind . '_' . $str;
    } else {
      return $prefix . $str;
    }
  };
}

{
  my %tmp;
  sub _all_funcs_in_class {
    my ($class) = @_;
    return $tmp{$class} if exists $tmp{$class};
    my %f;
    {
      no strict 'refs';
      @f{@{$class . '::EXPORT_OK'}, @{$class . '::EXPORT'}} = ();
    }
    return $tmp{$class} = [grep defined &{$class . '::' . $_}, keys %f];
  }
}

sub _do_export {
  my ($pkg, $caller, $class, $funcs, $want_funcs, $local_definition, $rename, $prefix, $kind_prefix) = @_;
  my %def_funcs;
  if (%$local_definition) {
    foreach my $func (keys %$local_definition) {
      next if %$want_funcs and not exists $want_funcs->{$func};
      foreach my $def (@{$local_definition->{$func}}) {
        if (ref $def eq 'HASH') {
          my $local_rename = delete $def->{-as} || '';
          my $defined = 0;
          {
            no strict 'refs';
            $defined = defined &{$class . '::' . $func};
            # $defined = $class->can($func);
          }
          if (!%$def and $defined) {
            ExportTo::export_to
                ($caller =>
                 {
                  ($local_rename ? $local_rename :
                   $prefix       ? (ref $prefix eq 'CODE' ? $prefix->($func) : $prefix . $func) :
                   $func)
                  => $class . '::' . $func
                 });
          } else {
            $def->{-as} = $local_rename;
          }
        } else {
          Carp::croak("setting for fucntions must be hash ref.");
        }
        $def_funcs{$func} = 1;
      }
    }
  } elsif (@$funcs) {
    no strict 'refs';
    @$funcs = grep defined &{$class . '::'. $_}, @$funcs;
    # @$funcs = grep defined $class->UNIVERSAL::can($_), @$funcs;
    return unless @$funcs;
  }

  my @export_funcs = grep !exists $def_funcs{$_}, ($kind_prefix or !@$funcs) ? @{_all_funcs_in_class($class)} : @$funcs;
  @export_funcs = grep exists $want_funcs->{$_}, @export_funcs if %$want_funcs;
  ExportTo::export_to($caller => ($prefix or %$rename)
                      ? {map {(ref $prefix ne 'CODE' ? $prefix . ($rename->{$_} || $_) : $prefix->($_)) => $class . '::' . $_} @export_funcs}
                      : [map $class . '::' . $_, List::MoreUtils::uniq @export_funcs]);
}

sub _insert_want_arg {
  my ($config, $kind, $setting, $want, $arg) = @_;
  $kind = lc $kind;
  exists $config->{$kind} ?
    $want->{$kind} = $setting:
    push @$arg, $kind, defined $setting ? $setting : ();
}

sub _arrange_args {
  my ($pkg, $org_args, $config, $caller) = @_;
  my (@arg, %want);
  my $import_module = $pkg->_use_import_module || '';
  if (@$org_args) {
    @$org_args = %{$org_args->[0]} if ref $org_args->[0] eq 'HASH';

    if (lc($org_args->[0]) eq 'all') {
      # import all functions which Util::Any proxy
      @want{keys %$config} = ();
    } elsif (lc($org_args->[0]) =~ /^[:-]all$/) {
      # import ALL functions
      @want{keys %$config} = ();
      if ($import_module) {
        if ($import_module eq 'Expoter'          or
            $import_module eq 'Exporter::Simple'
           ) {
          no strict 'refs';
          no warnings;
          push @arg, ':all' if ${$pkg . '::EXPORT_TAGS'}{":all"};
        } elsif ($import_module eq 'Sub::Exporter') {
          push @arg, '-all';
        } elsif ($import_module eq 'Perl6::Exporter::Attrs') {
          push @arg, ':ALL';
        }
      }
    } elsif (List::MoreUtils::any {ref $_} @$org_args) {
      for (my $i = 0; $i < @$org_args; $i++) {
        my $f = $org_args->[$i];
        my $setting = $org_args->[$i + 1] ? $org_args->[++$i] : undef;
        _insert_want_arg($config, $f, $setting, \%want, \@arg);
      }
    } else {
      # export specified kinds
      foreach my $f (@$org_args) {
        _insert_want_arg($config, $f, undef, \%want, \@arg);
      }
    }
  }
  $pkg->_do_base_import($import_module, $caller, \@arg) if (@arg or !@$org_args) and $import_module;
  return \@arg, \%want;
}

sub _func_definitions {
  my ($pkg, $kind, $want_func_definition, $kind_prefix) = @_;
  my (%funcs, %local_definition);
  if (ref $want_func_definition eq 'HASH') {
    # list => {func => {-as => 'rename'}};  list => {-prefix => 'hoge_' }
    $kind_prefix = $want_func_definition->{-prefix}
      if exists $want_func_definition->{-prefix};
    foreach my $f (grep !/^-/, keys %$want_func_definition) {
      $local_definition{$f} = [$want_func_definition->{$f}];
    }
  } elsif (ref $want_func_definition eq 'ARRAY') {
    foreach (my $i = 0; $i < @$want_func_definition; $i++) {
      my ($k, $v) = @{$want_func_definition}[$i, $i + 1];
      if (ref $v) {
        $i++;
        if ($k eq '-prefix') {
          $kind_prefix = $v;
        } else {
          push @{$funcs{$kind} ||= []}, $k;
          push @{$local_definition{$k} ||= []}, $v;
        }
      } else {
        push @{$funcs{$kind} ||= []}, $k;
      }
    }
    @{$funcs{$kind} ||= []} = List::MoreUtils::uniq @{$funcs{$kind} ||= []};
  }
  return \%funcs, \%local_definition, $kind_prefix || '';
}

sub _do_base_import {
  # working with other modules like Expoter
  my ($pkg, $import_module, $caller, $arg) = @_;
  my $pkg_utils;
  {
    no strict 'refs';
    no warnings;
    $pkg_utils = ${$pkg . '::Utils'};
  }
  if ($import_module eq 'Perl6::Export::Attrs') {
    eval "package $caller; $pkg" . '->Perl6::Export::Attrs::_generic_import(@$arg);';
  } elsif ($import_module eq 'Exporter::Simple') {
    eval "package $caller; $pkg" . '->Exporter::Simple::import(@$arg);';
  } elsif ($import_module eq 'Exporter') {
    eval "package $caller; $pkg" . '->Exporter::import(@$arg);';
  } elsif ($import_module eq 'Sub::Exporter') {
    no strict 'refs';
    no warnings;
    my $import_name =  ${"${pkg}::SubExporterImport"} || $Util::Any::SubExporterImport;
    eval "package $caller; $pkg" . '->$import_name(@$arg);';
  }
  die $@ if $@;
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
      require Perl6::Export::Attrs;
      *{$caller . '::MODIFY_CODE_ATTRIBUTES'} = \&Perl6::Export::Attrs::_generic_MCA;
      *{$caller . '::_use_import_module'} = sub { 'Perl6::Export::Attrs' };
    } elsif ($flg eq '-subexporter') {
      require Sub::Exporter;
      *{$caller . '::_use_import_module'} = sub { 'Sub::Exporter' };
    } elsif ($flg eq '-exportersimple') {
      require Exporter::Simple;
      *{$caller . '::_use_import_module'} = sub { 'Exporter::Simple' };
    } elsif ($flg eq '-exporter') {
      require Exporter;
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

Util::Any - to export any utilities and to create your own utilitiy module

=cut

our $VERSION = '0.13';

=head1 SYNOPSIS

    use Util::Any -list;
    # you can import any functions of List::Util and List::MoreUtils
    
    print uniq qw/1, 0, 1, 2, 3, 3/;

If you want to choose functions

    use Util::Any -list => ['uniq'];
    # you can import uniq function only, not import other functions
    
    print uniq qw/1, 0, 1, 2, 3, 3/;

If you want to import All kind of utility functions

    use Util::Any -all;
    
    my $o = bless {};
    my %hash = (a => 1, b => 2);
    
    # from Scalar::Util
    blessed $o;
    
    # from Hash::Util
    lock_keys %hash;

If you want to import functions with prefix(ex. list_, scalar_, hash_)

    use Util::Any -all, {prefix => 1};
    use Util::Any -list, {prefix => 1};
    use Util::Any -list => ['uniq', 'min'], {prefix => 1};
    
    print list_uniq qw/1, 0, 1, 2, 3, 3/;
   

If you want to import functions with your own prefix.

   use Util::Any -list => {-prefix => "l_"};
   print l_uniq qw/1, 0, 1, 2, 3, 3/;

If you want to import functions as different name.

   use Util::Any -list => {uniq => {-as => 'listuniq'}};
   print listuniq qw/1, 0, 1, 2, 3, 3/;

When you use both renaming and your own prefix ?

   use Util::Any -list => {uniq => {-as => 'listuniq'}, -prefix => "l_"};
   print listuniq qw/1, 0, 1, 2, 3, 3/;
   print l_min qw/1, 0, 1, 2, 3, 3/;
   # the following is NG
   print l_uniq qw/1, 0, 1, 2, 3, 3/;

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

 use YourUtil -list;

see C<CREATE YOUR OWN Util::Any>, in detail.

=head1 HOW TO USE

=head2 use Util::Any (KIND)

 use Util::Any -list, -hash;

Give list of kinds of modules. All functions in modules are exporeted.

=head2  use Util::Any KIND => [FUNCTIONS], ...;

 use Util::Any -list => ['uniq'], -hash => ['lock_keys'];

Give hash whose key is kind and value is function names as array ref.
Selected functions are exported.

you can write it as hash ref.

 use Util::Any {-list => ['uniq'], -hash => ['lock_keys']};

=head2  use Util::Any ..., {OPTION => VALUE};

Util::Any can take last argument as option, which should be hash ref.

=over 4

=item prefix => 1

add kind prefix to function name.

 use Util::Any -list, {prefix => 1};
 
 list_uniq(1,2,3,4,5); # it is List::More::Utils's uniq function

=item module_prefix => 1

see L<PREFIX FOR EACH MODULE>.
Uti::Any itself doesn't have such a definition.

=item smart_rename => 1

see L<SMART RENAME FOR EACH KIND>.

=item debug => 1/2

Util::Any doesn't say anything when loading module fails.
If you pass debug value, warn or die.

 use Util::Any -list, {debug => 1}; # warn
 use Util::Any -list, {debug => 2}; # die

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

=head1 EXPORTING LIKE Sub::Exporter

This feature is not enough tested. and only support '-prefix' and '-as'.

 use UtilSubExporter -list => {-prefix => 'list__', min => {-as => "list___min"}},
                     # The following is normal Sub::Exporter importing
                     greet => {-prefix => "greet_"},
                     'askme' => {-as => "ask_me"};

Check t/lib/UtilSubExporter.pm, t/10-sub-exporter-like-epxort.t and  t/12-sub-exporter-like-export.t

=head1 CREATE YOUR OWN Util::Any

Just inherit Util::Any and define $Utils hash ref as the following.

 package Util::Yours;
 
 use Clone qw/clone/;
 use Util::Any -Base; # or use base qw/Util::Any/;
 # If you don't want to inherit Util::Any setting, no need to clone.
 our $Utils = clone $Util::Any::Utils;
 push @{$Utils->{-list}}, qw/Your::Favorite::List::Utils/;
 
 1;

In your code;

 use Util::Yours -list;

=head2 $Utils STRUCTURE

=head3 overview

 $Utils => {
    # simply put module names
    -kind1 => [qw/Module1 Module2 ..../],
    -# Module name and its prefix
    -kind2 => [ [Module1 => 'module_prefix'], ... ],
    # limit functions to be exported
    -kind3 => [ [Module1, 'module_prefix', [qw/func1 func2/] ], ... ],
    # as same as above except not specify modul prefix
    -kind4 => [ [Module1, '', [qw/func1 func2/] ], ... ],
 };

=head3 Key must be lower character.

 NG $Utils = { LIST => [qw/List::Util/]};
 OK $Utils = { list => [qw/List::Util/]};
 OK $Utils = { -list => [qw/List::Util/]};
 OK $Utils = { ':list' => [qw/List::Util/]};

=head3 C<all> cannot be used for key.

 NG $Utils = { all    => [qw/List::Util/]};
 NG $Utils = { -all   => [qw/List::Util/]};
 NG $Utils = { ':all' => [qw/List::Util/]};

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

=head2 SMART RENAME FOR EACH KIND

smart_rename option rename function name by a little smart way.
For example,

 our $Utils = {
   utf8 => [['utf8', '',
             {
              is_utf8   => 'is_utf8',
              upgrade   => 'utf8_upgrade',
              downgrade => 'downgrade',
             }
            ]],
 };

In this definition, use C<prefix => 1> is not good idea. If you use it:

 is_utf8      => utf8_is_utf8
 utf8_upgrade => utf8_utf8_upgrade
 downgrade    => utf8_downgrade

That's too bad. If you use C<smart_rename => 1> instead:

 is_utf8      => is_utf8
 utf8_upgrade => utf8_upgrade
 downgrade    => utf8_downgrade

rename rule is represented in _create_smart_rename in Util::Any.

=head2 CHANGE smart_rename BEHAVIOUR

To define _create_smart_rename, you can change smart_rename behaviour.
_create_smart_rename get 2 argument, package name and kind of utilitiy,
and should return code reference which get function name and return new name.
As an example, see Util::Any's _create_smart_rename.

=head2 OTHER WAY TO EXPORT FUNCTIONS

=head3 SELECT FUNCTIONS

Util::Any automatically export functions from modules' @EXPORT and @EXPORT_OK.
In some cases, it is not good idea like Data::Dumper's Dumper and DumperX.
Tease 2 functions are same feature.

So you can limit functions to be exported.

 our $Utils = {
      -debug => [
                ['Data::Dumper', '',
                ['Dumper']], # only Dumper method is exported.
               ],
 };

or

 our $Utils = {
      -debug => [
                ['Data::Dumper', '',
                 { -select => ['Dumper'] }, # only Dumper method is exported.
                ]
               ],
 };


=head3 SELECT FUNCTIONS EXCEPT

Inverse of -select option. Cannot use this option with -select.

 our $Utils = {
      -debug => [
                ['Data::Dumper', '',
                 { -except => ['DumperX'] }, # export functions except DumperX
                ]
               ],
 };

=head3 RENAME FUNCTIONS

To rename function name, use this option with -select or -exception,
this definition is prior to them.

In the following example, 'min' is not in -select list, but can be exported.

 our $Utils = {
      -list  => [
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

=head3 USE Sub::Exporter's GENERATOR WAY

It's somewhat complicate, I just show you code.

Your utility class:

  package SubExporterGenerator;
  
  use strict;
  use Util::Any -Base;
  
  our $Utils =
    {
     -test => [[
               'List::Util', '',
               { min => \&build_min_reformatter,}
              ]]
    };
  
  sub build_min_reformatter {
    my ($pkg, $class, $name, @option) = @_;
    no strict 'refs';
    my $code = do { no strict 'refs'; \&{$class . '::' . $name}};
    sub {
      my @args = @_;
      $code->(@args, $option[0]->{under} || ());
    }
  }

Your script using your utility class:

 package main;
 
 use strict;
 use lib qw(lib t/lib);
 use SubExporterGenerator -test => [
       min => {-as => "min_under_20", under => 20},
       min => {-as => "min_under_5" , under => 5},
     ];
 
 print min_under_20(100,25,30); # 20
 print min_under_20(100,10,30); # 10
 print min_under_20(100,25,30); # 5
 print min_under_20(100,1,30);  # 1

If you don't specify C<-as>, C<min> is exported with arguments.
But, of course, the following doesn't work.

 use SubExporterGenerator -test => [
       min => {under => 20},
       min => {under => 5},
     ];

Util::Any export duplicate function C<min>.

=head1 WORKING WITH EXPORTER-LIKE MODULES

CPAN has some modules to export functions.
Util::Any can work with some of such modules, L<Exporter>, L<Exporter::Simple>, L<Sub::Exporter> and L<Perl6::Export::Attrs>.
If you want to use other modules, please inform me or implement import method by yourself.

If you want to use module mentioned above, you have to change the way to inherit these modules.

=head2 DIFFERENCE between 'all' and '-all' or ':all'

If your utility module which inherited Util::Any has utility functions and export them by Exporter-like module,
behaviour of 'all' and '-all' or ':all' is a bit different.

 'all' ... export all utilities defined in your package's $Utils variables.
 '-all' or ':all' ... export all utilities including functions in your util module itself.

=head2 ALTERNATIVE INHERITING

Normally, you use;

 package YourUtils;
 
 use Util::Any -Base; # or "use base qw/Util::Any/;"

But, if you want to use L<Exporter>, L<Exporter::Simple> or L<Perl6::Export::Attrs>.
write as the following, instead.

 # if you want to use Exporter
 use Util::Any -Exporter;
 # if you want to use Exporter::Simple
 use Util::Any -ExporterSimple;
 # if you want to use Sub::Exporter
 use Util::Any -SubExporter;
 # if you want to use Perl6::Export::Attrs
 use Util::Any -Perl6ExportAttrs;

That's all.
Note that B<don't use base the above modules in your utility module>.

There is one notice to use Sub::Exporter.

 Sub::Exporter::setup_exporter
       ({
           as => 'do_import', # name is important
           exports => [...],
           groups  => { ... },
       });

You must pass "as" option to setup_exporter and its value must be "do_import".
If you want to change this name, do the following.

 Sub::Exporter::setup_exporter
       ({
           as => $YourUtils::SubExporterImport = '__do_import',
           exports => [...],
           groups  => { ... },
       });

=head3 EXAMPLE to USE Perl6::Export::Attrs in YOUR OWN UTIL MODULE

Perl6::Export::Attributes is not recommended in the following URL
(http://www.perlfoundation.org/perl5/index.cgi?pbp_module_recommendation_commentary).
So, you'd better use other exporter module. It is left as an example.

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

Perl6::Export::Attributes is not recommended in the following URL
(http://www.perlfoundation.org/perl5/index.cgi?pbp_module_recommendation_commentary).
So, you'd better use other exporter module. It is left as an example.

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

=head1 SEE ALSO

The following modules can work with Util::Any.

L<Exporter>, L<Exporter::Simple>, L<Sub::Exporter> and L<Perl6::Export::Attrs>.

The following is new module L<Util::All>, based on Util::Any.

 http://github.com/ktat/Util-All

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2008-2009 Ktat, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Util-Any
