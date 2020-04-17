#!/bin/bash

PSQL="psql postgresql://postgres:postgres@172.17.0.3:5432"

mkdir -p data
for table in $($PSQL -t -c "SELECT table_name FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE';"); do
  echo "exporting table $table to data/$table.csv"
  $PSQL -c "copy (select * from $table) to stdout" > data/$table.csv
done


