#!/usr/bin/env bash

input_file=$1
n=0

while read -r line
do
  [[ $line =~ .*([0-9]+) ]]
  last_digit=${BASH_REMATCH[1]}
  reversed_line=$(echo $line | rev)
  [[ $reversed_line =~ .*([0-9]+) ]]
  first_digit=$(echo ${BASH_REMATCH[1]})
  incr="$first_digit$last_digit"
  n=$((n+incr))
done < $input_file

echo $n
