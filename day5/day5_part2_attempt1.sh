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

duckdb $db_file "create table seed_ranges(range_start long, range_end long)"
for ((i=0; i<${#seeds[@]}; i+=2))
do
  j=$((i+1))
  seed=${seeds[$i]}
  range=${seeds[$j]}
  duckdb $db_file "insert into seed_ranges (range_start, range_end) values ($seed, $((seed+range)))"
done

function check_seed_in_range() {
  seed=$1
  duckdb $db_file -csv -noheader "select count(1) from seed_ranges where $seed between range_start and range_end"
}

min_location=
while read -r location
do
  echo "location: $location"
  seed=$(duckdb -csv -noheader $db_file <<EOF
    with humidity as (
      select coalesce(
        (select source_start + $location - dest_start
        from 'humidity-to-location'
        where $location between dest_start and dest_end),
        $location
      ) as value
    ), temperature as (
      select coalesce(
        (select source_start + (select value from humidity) - dest_start
        from 'temperature-to-humidity'
        where (select value from humidity) between dest_start and dest_end),
        (select value from humidity)
      ) as value
    ), light as (
      select coalesce(
        (select source_start + (select value from temperature) - dest_start
        from 'light-to-temperature'
        where (select value from temperature) between dest_start and dest_end),
        (select value from temperature)
      ) as value
    ), water as (
      select coalesce(
        (select source_start + (select value from light) - dest_start
        from 'water-to-light'
        where (select value from light) between dest_start and dest_end),
        (select value from light)
      ) as value
    ), fertilizer as (
      select coalesce(
        (select source_start + (select value from water) - dest_start
        from 'fertilizer-to-water'
        where (select value from water) between dest_start and dest_end),
        (select value from water)
      ) as value
    ), soil as (
      select coalesce(
        (select source_start + (select value from fertilizer) - dest_start
        from 'soil-to-fertilizer'
        where (select value from fertilizer) between dest_start and dest_end),
        (select value from fertilizer)
      ) as value
    ), seed as (
      select coalesce(
        (select source_start + (select value from soil) - dest_start
        from 'seed-to-soil'
        where (select value from soil) between dest_start and dest_end),
        (select value from soil)
      ) as value
    )
    select value from seed
EOF
  )
  echo "seed: $seed"

  is_seed_in_range=$(check_seed_in_range $seed)
  if [[ $is_seed_in_range -eq 1 ]]
  then
    echo "In range!"

    if [[ -z $min_location || "$location" -lt "$min_location" ]]
    then
      min_location=$location
    fi
  fi
done < <(duckdb -csv -noheader $db_file "select dest_start from 'humidity-to-location' union select dest_end from 'humidity-to-location'")

if [[ ! -z $min_location ]]
then
  echo "The smallest location range boundary is $min_location"
fi
