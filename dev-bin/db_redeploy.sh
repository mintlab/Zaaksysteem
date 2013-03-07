#!/bin/sh

rootdir=`dirname $0`'/../';
$rootdir/script/zaaksysteem_create.pl model DB DBIC::Schema Zaaksysteem::Schema create=static components=InflateColumn::DateTime,TimeStamp dbi:Pg:dbname=zaaksysteem_beheer_template
$rootdir/script/zaaksysteem_create.pl model DBG DBIC::Schema Zaaksysteem::SchemaGM create=static components=InflateColumn::DateTime,TimeStamp dbi:Pg:dbname=zaaksysteem_gegevens_template
