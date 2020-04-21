#!/bin/bash

suffix=$1
PSQL="psql postgresql://postgres:postgres@db:5432"

data_dir=data$suffix
mkdir -p $data_dir 
for table in $($PSQL -t -c "SELECT table_name FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE';"); do
  f=$table
  if [ "$suffix" == "_tmp" ]; then
    [ "${table: -4}" == "_tmp" ] || continue
    f=${table::-4}
  fi
  echo "exporting table $table to $data_dir/$f.csv"
  $PSQL -c "copy (select * from $table) to stdout" > $data_dir/$f.csv
done


