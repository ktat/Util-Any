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
        'Test::More'      => 0,
	'ExportTo'        => 0,
	'List::Util'      => 0,
	'List::MoreUtils' => 0,
	'Hash::Util'      => 0,
	'Scalar::Util'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Util-Any-*' },
);
