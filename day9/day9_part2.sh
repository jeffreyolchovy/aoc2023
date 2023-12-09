#!/usr/bin/env bash

input_file=$1

function compute_deltas() {
  awk 'NR==1 {a=$1;next} {print $1-a;a=$1}'
}

declare -a prev_ns
while read -r line
do
  ns=$(echo $line | tr ' ' "\n")
  declare -a first_ns=($(echo "$ns" | head -n 1))

  while :
  do
    deltas=$(echo "$ns" | compute_deltas)
    ns=$deltas
    first_ns+=($(echo "$deltas" | head -n 1))
    distinct_ns=$(echo "$deltas" | uniq | tr -d '[:space:]')
    [[ "$distinct_ns" != "0" ]] || break
  done

  prev_n=0
  for n in $(echo "${first_ns[@]}" | tr ' ' "\n" | tail -r)
  do
    prev_n=$((n-prev_n))
  done
  echo "Previous number in sequence is $prev_n"
  prev_ns+=($prev_n)
done < $input_file

for n in "${prev_ns[@]}"
do
  result=$((result+n))
done

echo "Sum of all previous numbers in each sequence is $result"
