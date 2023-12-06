#!/usr/bin/env bash

input_file=$1

times=($(head -n 1 < $input_file | cut -d ' ' -f 2-))
distances=($(tail -n 1 < $input_file | cut -d ' ' -f 2-))

declare -a all_num_wins
for ((i=0; i<${#times[@]}; i++))
do
  time=${times[$i]}
  distance_record=${distances[$i]}
  num_wins=0
  for velocity in $(seq 1 $((time-1)))
  do
    travel_time=$((time-velocity))
    total_distance=$((travel_time*velocity))
    if [[ "$total_distance" -gt "$distance_record" ]]
    then
      num_wins=$((num_wins+1))
    fi
  done
  all_num_wins+=($num_wins)
done

acc=1
for n in ${all_num_wins[@]}
do
  acc=$((acc*n))
done

echo $acc
