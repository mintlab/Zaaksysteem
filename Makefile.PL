#!/usr/bin/env perl
# IMPORTANT: if you delete this file your app will not work as
# expected.  You have been warned.
use inc::Module::Install;

name 'Zaaksysteem';
all_from 'lib/Zaaksysteem.pm';

requires 'Catalyst::Runtime' => '5.80007';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Static::Simple';
requires 'parent';
requires 'Catalyst::Plugin::Session';
requires 'Catalyst::Plugin::Session::Store::File';
requires 'Catalyst::Plugin::Authorization::Roles';
requires 'Catalyst::Plugin::ClamAV';
requires 'Catalyst::Plugin::Params::Profile';
requires 'Catalyst::Plugin::Unicode::Encoding';
requires 'Catalyst::Plugin::I18N';
requires 'Catalyst::Action::RenderView';
requires 'Catalyst::Action::REST';
requires 'Catalyst::Authentication::Store::LDAP';
requires 'Catalyst::Controller::SOAP';
requires 'Catalyst::Model::DBIC::Schema';
requires 'Catalyst::Model::Adaptor';
requires 'Catalyst::View::JSON';
requires 'Catalyst::View::Email';
requires 'Catalyst::View::Download';
requires 'Catalyst::View::TT';
requires 'Config::General';
requires 'Moose';
requires 'MooseX::Aliases';
requires 'MooseX::Clone';
requires 'MooseX::Emulate::Class::Accessor::Fast';
requires 'MooseX::Getopt';
requires 'MooseX::Params::Validate';
requires 'MooseX::MethodAttributes';
requires 'MooseX::Role::WithOverloading';
requires 'MooseX::SemiAffordanceAccessor';
requires 'MooseX::Storage';
requires 'MooseX::Traits::Pluggable';
requires 'MooseX::Types';
requires 'MooseX::Types::Common';
requires 'Params::Profile';
requires 'Data::UUID';
requires 'Geo::Coder::Google';
requires 'Any::Moose';
requires 'AppConfig';
requires 'Archive::Zip';
requires 'Data::FormValidator';
requires 'DateTime';
requires 'DBIx::Class' => '0.08195';
requires 'DBIx::Class::TimeStamp';
requires 'DBIx::Class::Cursor::Cached';
requires 'DBIx::Class::Schema::Loader';
requires 'DBIx::ContextualFetch';
requires 'DBIx::DBSchema';
requires 'DBIx::SearchBuilder';
requires 'DBIx::Class::Helper::ResultSet::SetOperations';
requires 'GnuPG::Interface';
requires 'JSON';
requires 'Log::Dispatch';
requires 'Log::Log4perl';
requires 'MIME::Lite';
requires 'MIME::Tools';
requires 'MIME::Types';
requires 'Module::Pluggable::Fast';
requires 'XML::Parser';
requires 'XML::Twig';
requires 'OpenOffice::OODoc';
requires 'Text::CSV';
requires 'UUID';
requires 'Net::LDAP';
requires 'ClamAV::Client';
requires 'Net::LDAP::Server';
requires 'HTML::TagFilter';
requires 'Hash::Merge::Simple';
requires 'Digest::MD5';
requires 'Unicode::String';
requires 'XML::Dumper';
requires 'Clone';
requires 'Image::Magick';
requires 'Digest::MD5::File';
requires 'Data::Serializer' => '0.59';
requires 'FCGI::ProcManager';
requires 'FCGI::ProcManager::MaxRequests';
requires 'DateTime::Format::Pg';
requires 'File::Copy';

# Will never work, no version
requires 'XML::Tidy';

license 'eupl';

catalyst;

install_script glob(
    join(' ', 
        'script/zaaksysteem_fastcgi.pl',
        'script/zaaksysteem_setup.pl',
        'script/zaaksysteem_server.pl'
    )
);
auto_install;
WriteAll;
