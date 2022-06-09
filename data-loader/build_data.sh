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
curl -sfL https://cnecovid.isciii.es/covid19/resources/casos_hosp_uci_def_sexo_edad_provres.csv > data/casos_hosp_uci_def_sexo_edad_provres.csv
./bin/consolidate_spain.py > data/spain.csv
#curl -fL https://covid19.isciii.es/resources/serie_historica_acumulados.csv | LC_ALL=C sed -n '/NOTA.*/q;p' > data/serie_historica_acumulados.csv
# --> check that it looks fine
#echo "testing Spain data"
#head -2 data/serie_historica_acumulados.csv | tail -1 | grep 2020

# France official data
curl -fL https://raw.githubusercontent.com/opencovid19-fr/data/master/dist/chiffres-cles.csv > data/chiffres-cles.csv

# UK official data
curl -fL https://raw.githubusercontent.com/tomwhite/covid-19-uk-data/master/data/covid-19-indicators-uk.csv > data/covid_19_indicators_uk.csv
python2 bin/consolidate_uk.py > data/uk.csv

# Germany official data
curl -fL https://raw.githubusercontent.com/micgro42/COVID-19-DE/master/time_series/time-series_19-covid-Confirmed.csv > data/time_series_covid19_confirmed_Germany.csv
curl -fL https://raw.githubusercontent.com/micgro42/COVID-19-DE/master/time_series/time-series_19-covid-Deaths.csv > data/time_series_covid19_deaths_Germany.csv
python2 bin/consolidate_germany.py > data/germany.csv


a='''
# Population data
curl -fL "https://docs.google.com/spreadsheets/d/1e703pe3GmBQt0i2yAOS0F6Bhxy91U1-NTB6JMRSTzc0/export?format=csv&id=1e703pe3GmBQt0i2yAOS0F6Bhxy91U1-NTB6JMRSTzc0&gid=0" > population-data/population-World.csv
curl -fL "https://docs.google.com/spreadsheets/d/1e703pe3GmBQt0i2yAOS0F6Bhxy91U1-NTB6JMRSTzc0/export?format=csv&id=1e703pe3GmBQt0i2yAOS0F6Bhxy91U1-NTB6JMRSTzc0&gid=1662739553" > population-data/population-Australia.csv
curl -fL "https://docs.google.com/spreadsheets/d/1e703pe3GmBQt0i2yAOS0F6Bhxy91U1-NTB6JMRSTzc0/export?format=csv&id=1e703pe3GmBQt0i2yAOS0F6Bhxy91U1-NTB6JMRSTzc0&gid=702355833" > population-data/population-China.csv
curl -fL "https://docs.google.com/spreadsheets/d/1e703pe3GmBQt0i2yAOS0F6Bhxy91U1-NTB6JMRSTzc0/export?format=csv&id=1e703pe3GmBQt0i2yAOS0F6Bhxy91U1-NTB6JMRSTzc0&gid=88045307" > population-data/population-Canada.csv
curl -fL "https://docs.google.com/spreadsheets/d/1e703pe3GmBQt0i2yAOS0F6Bhxy91U1-NTB6JMRSTzc0/export?format=csv&id=1e703pe3GmBQt0i2yAOS0F6Bhxy91U1-NTB6JMRSTzc0&gid=334671180" > population-data/population-Italy.csv
curl -fL "https://docs.google.com/spreadsheets/d/1e703pe3GmBQt0i2yAOS0F6Bhxy91U1-NTB6JMRSTzc0/export?format=csv&id=1e703pe3GmBQt0i2yAOS0F6Bhxy91U1-NTB6JMRSTzc0&gid=117825319" > population-data/population-Spain.csv
curl -fL "https://docs.google.com/spreadsheets/d/1e703pe3GmBQt0i2yAOS0F6Bhxy91U1-NTB6JMRSTzc0/export?format=csv&id=1e703pe3GmBQt0i2yAOS0F6Bhxy91U1-NTB6JMRSTzc0&gid=1500184457" > population-data/population-UK.csv
curl -fL "https://docs.google.com/spreadsheets/d/1e703pe3GmBQt0i2yAOS0F6Bhxy91U1-NTB6JMRSTzc0/export?format=csv&id=1e703pe3GmBQt0i2yAOS0F6Bhxy91U1-NTB6JMRSTzc0&gid=2101017542" > population-data/population-Germany.csv
curl -fL "https://docs.google.com/spreadsheets/d/1e703pe3GmBQt0i2yAOS0F6Bhxy91U1-NTB6JMRSTzc0/export?format=csv&id=1e703pe3GmBQt0i2yAOS0F6Bhxy91U1-NTB6JMRSTzc0&gid=1101367004" > population-data/population-France.csv
curl -fL "https://docs.google.com/spreadsheets/d/1e703pe3GmBQt0i2yAOS0F6Bhxy91U1-NTB6JMRSTzc0/export?format=csv&id=1e703pe3GmBQt0i2yAOS0F6Bhxy91U1-NTB6JMRSTzc0&gid=1285380985" > population-data/population-USA.csv
'''


function get_table_name {
  local f=$1
  echo $f | cut -d '.' -f 1 | sed 's/-/_/g'
}

PSQL="psql postgresql://postgres:postgres@db:5432"
echo "data retrieved, loading to database"
for f in $(ls data); do
  table=$(get_table_name $f)
  f=data/$f
  sed 's/"/"""/g' $f > $f.tmp && mv $f.tmp $f
  $PSQL -c "drop table if exists ${table}_tmp; create table ${table}_tmp (data varchar(10000));"
  cat $f | $PSQL -c "copy ${table}_tmp from stdin csv delimiter '}';"
done

echo "checking if api exists, and ensuring it does not transition from working to broken"
if curl -v --fail "api/covid?refresh=true" > /dev/null; then
  curl -v --fail "api/covid?refresh=true&suffix=_tmp" > /dev/null
fi

echo "updating main data"
for f in $(ls data); do
  table=$(get_table_name $f)
  $PSQL -c "drop table if exists ${table}"
  $PSQL -c "alter table ${table}_tmp rename to ${table};"
done

echo "data load completed"

if curl -v --fail "api/covid?refresh=true" > /dev/null; then
  echo "updating cache"
  ab -n 4 -c 2 -s 180 'http://api/covid?refresh=true'
  echo "cache updated"
fi

exit 0
