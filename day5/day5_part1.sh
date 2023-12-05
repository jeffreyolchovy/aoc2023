#!/usr/bin/env bash

input_file=$1
db_file=$2

[ -e "$db_file" ] && rm "$db_file"

declare -a seeds=($(head -n 1 < $input_file | cut -d ' ' -f 2-))
declare -a maps=(
  "seed-to-soil"
  "soil-to-fertilizer"
  "fertilizer-to-water"
  "water-to-light"
  "light-to-temperature"
  "temperature-to-humidity"
  "humidity-to-location"
)

function expand_map() {
  map=$1
  while read -r dest_start source_start range
  do
    source_end=$((source_start+range-1))
    dest_end=$((dest_start+range-1))
    duckdb $db_file <<EOF
      insert into '$map' (source_start, source_end, dest_start, dest_end) values (
        $source_start, $source_end, $dest_start, $dest_end
      );
EOF
  done
}

function get_map_input() {
  pattern=$1
  awk "/$1/" RS= $input_file | tail -n +2
}

for map in ${maps[@]}
do
  duckdb $db_file "create table '$map'(source_start long, source_end long, dest_start long, dest_end long)"
  get_map_input $map | expand_map $map
done

min_location=
for seed in ${seeds[@]}
do
  location=$(duckdb -csv -noheader $db_file <<EOF
    with soil as (
      select coalesce(
        (select dest_start + $seed - source_start
        from 'seed-to-soil'
        where $seed between source_start and source_end),
        $seed
      ) as value
    ), fertilizer as (
      select coalesce(
        (select dest_start + (select value from soil) - source_start
        from 'soil-to-fertilizer'
        where (select value from soil) between source_start and source_end),
        (select value from soil)
      ) as value
    ), water as (
      select coalesce(
        (select dest_start + (select value from fertilizer) - source_start
        from 'fertilizer-to-water'
        where (select value from fertilizer) between source_start and source_end),
        (select value from fertilizer)
      ) as value
    ), light as (
      select coalesce(
        (select dest_start + (select value from water) - source_start
        from 'water-to-light'
        where (select value from water) between source_start and source_end),
        (select value from water)
      ) as value
    ), temperature as (
      select coalesce(
        (select dest_start + (select value from light) - source_start
        from 'light-to-temperature'
        where (select value from light) between source_start and source_end),
        (select value from light)
      ) as value
    ), humidity as (
      select coalesce(
        (select dest_start + (select value from temperature) - source_start
        from 'temperature-to-humidity'
        where (select value from temperature) between source_start and source_end),
        (select value from temperature)
      ) as value
    ), location as (
      select coalesce(
        (select dest_start + (select value from humidity) - source_start
        from 'humidity-to-location'
        where (select value from humidity) between source_start and source_end),
        (select value from humidity)
      ) as value
    )
    select value from location
EOF
  )
  
  if [[ -z "$min_location" || "$location" -lt "$min_location" ]]
  then
    min_location=$location
  fi
done

echo "The smallest location is $min_location"
