#!/usr/bin/env bash

input_file=$1
n_procs=${2:-1}

time=$(head -n 1 < $input_file | cut -d ' ' -f 2)
distance_record=$(tail -n 1 < $input_file | cut -d ' ' -f 2)

declare -a tmp_files_in
declare -a tmp_files_out

for i in $(seq 0 $((n_procs-1)))
do
  tmp_file_in=$(mktemp)
  tmp_file_out=$(mktemp)
  echo "Created temporary file $tmp_file_in for input shard $i"
  echo "Created temporary file $tmp_file_out for output shard $i"
  tmp_files_in+=($tmp_file_in)
  tmp_files_out+=($tmp_file_out)
done

for ((i=1; i<$time; i++))
do
  shard=$((i % n_procs))
  echo "$i" >> ${tmp_files_in[$shard]}
done

function process_shard() {
  tmp_file_in=$1
  tmp_file_out=$2
  echo "Processing shard of input @ $tmp_file_in"
  while read -r velocity
  do
    travel_time=$((time-velocity))
    total_distance=$((travel_time*velocity))
    if [[ "$total_distance" -gt "$distance_record" ]]
    then
      echo 1 >> $tmp_file_out
    fi
  done < $tmp_file_in
}

for i in $(seq 0 $(($n_procs-1)))
do
  process_shard ${tmp_files_in[$i]} ${tmp_files_out[$i]} &
done

wait

awk '{s+=$1} END {print s}' "${tmp_files_out[@]}"
