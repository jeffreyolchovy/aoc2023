#!/usr/bin/env bash

input_file=$1

function compute_deltas() {
  awk 'NR==1 {a=$1;next} {print $1-a;a=$1}'
}

declare -a next_ns
while read -r line
do
  ns=$(echo $line | tr ' ' "\n")
  declare -a last_ns=($(echo "$ns" | tail -n 1))

  while :
  do
    deltas=$(echo "$ns" | compute_deltas)
    ns=$deltas
    last_ns+=($(echo "$deltas" | tail -n 1))
    distinct_ns=$(echo "$deltas" | uniq | tr -d '[:space:]')
    [[ "$distinct_ns" != "0" ]] || break
  done

  next_n=0
  for n in "${last_ns[@]}"
  do
    next_n=$((next_n+n))
  done
  echo "Next number in sequence is $next_n"
  next_ns+=($next_n)
done < $input_file

for n in "${next_ns[@]}"
do
  result=$((result+n))
done

echo "Sum of all next numbers in each sequence is $result"
