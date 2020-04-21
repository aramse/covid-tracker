#!/bin/bash

suffix=$1
PSQL="psql postgresql://postgres:postgres@db:5432"

data_dir=data$suffix
mkdir -p $data_dir 
for table in $($PSQL -t -c "SELECT table_name FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE';"); do
  db_table=${table}${suffix}
  echo "exporting table $db_table to $data_dir/$table.csv"
  $PSQL -c "copy (select * from $db_table) to stdout" > $data_dir/$table.csv
done


