use Test::More 'no_plan';
use lib qw(./lib t/lib);
use Util::Any ();
use exampleHello ();

is_deeply([sort @{Util::Any::_all_funcs_in_class('exampleHello')}], [sort qw/hello_name hello_where/]);


Util::Any->_base_import('main', "-Perl6ExportAttrs");
is(main->_use_import_module, "Perl6::Export::Attrs");
undef &_use_import_module;
Util::Any->_base_import('main', "-SubExporter");
is(main->_use_import_module, "Sub::Exporter");
undef &_use_import_module;
Util::Any->_base_import('main', "-ExporterSimple");
is(main->_use_import_module, "Exporter::Simple");
undef &_use_import_module;
Util::Any->_base_import('main', "-Exporter");
is(main->_use_import_module, "Exporter");
undef &_use_import_module;


