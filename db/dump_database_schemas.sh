#!/bin/sh

echo "SET SESSION AUTHORIZATION zaaksysteem;" > $DBNAME.sql
echo "SET SESSION AUTHORIZATION zaaksysteem;" > $DBNAME.sql
pg_dump -O -x -c --schema-only $DBNAME >> $DBNAME.sql
pg_dump -O -x -c --schema-only $DBNAME >> $DBNAME.sql
