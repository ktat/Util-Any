use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Util::Any',
    AUTHOR              => 'Ktat <ktat@cpan.org>',
    VERSION_FROM        => 'lib/Util/Any.pm',
    ABSTRACT_FROM       => 'lib/Util/Any.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Clone'             => 0,
        'Test::More'        => 0,
	'ExportTo'          => 0,
	'List::Util'        => 0,
	'List::MoreUtils'   => 0,
	'Hash::Util'        => 0,
	'Scalar::Util'      => 0,
	'Data::Dumper'      => 0,
	'String::Util'      => 0,
	'String::CamelCase' => 0,
	'Module::Pluggable' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Util-Any-*' },
);
