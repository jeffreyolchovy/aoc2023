#!/usr/bin/env bash

input_file=$1
db_file=$2
range_start=$3
range_end=$4
range_step=${5:-1}
range_step=$([[ $range_start -lt $range_end ]] && echo $range_step || echo "-$range_step")

function check_seed_in_range() {
  seed=$1
  duckdb $db_file -readonly -csv -noheader "select count(1) from seed_ranges where $seed between range_start and range_end"
}

min_location=
while read -r location
do
  echo "location: $location"
  seed=$(duckdb -readonly -csv -noheader $db_file <<EOF
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
done < <(duckdb -readonly -csv -noheader $db_file "select unnest(generate_series($range_start, $range_end, $range_step))")

if [[ ! -z $min_location ]]
then
  echo "$min_location is the smallest location found thus far. Adjust range and step and try again."
fi
