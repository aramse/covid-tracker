#!/bin/bash

set -e

mkdir -p data

# World JHU data
for typ in confirmed deaths recovered; do
  curl -fL https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_${typ}_global.csv > data/time_series_covid19_${typ}_global.csv
done;

# USA JHU data
for typ in confirmed deaths; do # testing; do
  curl -fL https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_${typ}_US.csv > data/time_series_covid19_${typ}_US.csv
done;

# Italy official data
curl -fL https://raw.githubusercontent.com/pcm-dpc/COVID-19/master/dati-regioni/dpc-covid19-ita-regioni.csv > data/dpc-covid19-ita-regioni.csv

# Spain official data
curl -fL https://covid19.isciii.es/resources/serie_historica_acumulados.csv | head -n -5 > data/serie_historica_acumulados.csv

# France official data
curl -fL https://raw.githubusercontent.com/opencovid19-fr/data/master/dist/chiffres-cles.csv > data/chiffres-cles.csv

# UK official data
curl -fL https://raw.githubusercontent.com/tomwhite/covid-19-uk-data/master/data/covid-19-indicators-uk.csv > data/covid-19-indicators-uk.csv
python bin/consolidate_uk.py > data/uk.csv

# Germany official data
curl -fL https://raw.githubusercontent.com/micgro42/COVID-19-DE/master/time_series/time-series_19-covid-Confirmed.csv > data/time_series_covid19_confirmed_Germany.csv
curl -fL https://raw.githubusercontent.com/micgro42/COVID-19-DE/master/time_series/time-series_19-covid-Deaths.csv > data/time_series_covid19_deaths_Germany.csv
python bin/consolidate_germany.py > data/germany.csv


a='''
# Population data
curl -fL "https://docs.google.com/spreadsheets/d/1e703pe3GmBQt0i2yAOS0F6Bhxy91U1-NTB6JMRSTzc0/export?format=csv&id=1e703pe3GmBQt0i2yAOS0F6Bhxy91U1-NTB6JMRSTzc0&gid=0" > data/population-World.csv
curl -fL "https://docs.google.com/spreadsheets/d/1e703pe3GmBQt0i2yAOS0F6Bhxy91U1-NTB6JMRSTzc0/export?format=csv&id=1e703pe3GmBQt0i2yAOS0F6Bhxy91U1-NTB6JMRSTzc0&gid=1662739553" > data/population-Australia.csv
curl -fL "https://docs.google.com/spreadsheets/d/1e703pe3GmBQt0i2yAOS0F6Bhxy91U1-NTB6JMRSTzc0/export?format=csv&id=1e703pe3GmBQt0i2yAOS0F6Bhxy91U1-NTB6JMRSTzc0&gid=702355833" > data/population-China.csv
curl -fL "https://docs.google.com/spreadsheets/d/1e703pe3GmBQt0i2yAOS0F6Bhxy91U1-NTB6JMRSTzc0/export?format=csv&id=1e703pe3GmBQt0i2yAOS0F6Bhxy91U1-NTB6JMRSTzc0&gid=88045307" > data/population-Canada.csv
curl -fL "https://docs.google.com/spreadsheets/d/1e703pe3GmBQt0i2yAOS0F6Bhxy91U1-NTB6JMRSTzc0/export?format=csv&id=1e703pe3GmBQt0i2yAOS0F6Bhxy91U1-NTB6JMRSTzc0&gid=334671180" > data/population-Italy.csv
curl -fL "https://docs.google.com/spreadsheets/d/1e703pe3GmBQt0i2yAOS0F6Bhxy91U1-NTB6JMRSTzc0/export?format=csv&id=1e703pe3GmBQt0i2yAOS0F6Bhxy91U1-NTB6JMRSTzc0&gid=117825319" > data/population-Spain.csv
curl -fL "https://docs.google.com/spreadsheets/d/1e703pe3GmBQt0i2yAOS0F6Bhxy91U1-NTB6JMRSTzc0/export?format=csv&id=1e703pe3GmBQt0i2yAOS0F6Bhxy91U1-NTB6JMRSTzc0&gid=1500184457" > data/population-UK.csv
curl -fL "https://docs.google.com/spreadsheets/d/1e703pe3GmBQt0i2yAOS0F6Bhxy91U1-NTB6JMRSTzc0/export?format=csv&id=1e703pe3GmBQt0i2yAOS0F6Bhxy91U1-NTB6JMRSTzc0&gid=2101017542" > data/population-Germany.csv
curl -fL "https://docs.google.com/spreadsheets/d/1e703pe3GmBQt0i2yAOS0F6Bhxy91U1-NTB6JMRSTzc0/export?format=csv&id=1e703pe3GmBQt0i2yAOS0F6Bhxy91U1-NTB6JMRSTzc0&gid=1101367004" > data/population-France.csv
curl -fL "https://docs.google.com/spreadsheets/d/1e703pe3GmBQt0i2yAOS0F6Bhxy91U1-NTB6JMRSTzc0/export?format=csv&id=1e703pe3GmBQt0i2yAOS0F6Bhxy91U1-NTB6JMRSTzc0&gid=1285380985" > data/population-USA.csv
'''

PSQL="psql postgresql://postgres:postgres@db:5432"
echo "data retrieved, loading to database"
for f in $(ls data); do
  table=$(echo $f | cut -d '.' -f 1 | sed 's/-/_/g')
  $PSQL -c "drop table if exists ${table}_tmp; create table ${table}_tmp (data varchar(10000));"
  cat data/$f | $PSQL -c "copy ${table}_tmp from stdin csv delimiter '}' header;"
  $PSQL -c "drop table if exists ${table}"
  $PSQL -c "alter table ${table}_tmp rename to ${table};"
done

echo "data load completed"

[ "$1" == "refresh" ] && echo "refreshing api cache" && curl --fail "api/covid?refresh=true"
