#!/usr/bin/env bash

input_file=$1

function trim() {
  awk '{$1=$1;print}'
}

total_score=0

while read -r line
do
  [[ $line =~ ^(Card)( +)([0-9]+)(: )(.*)$ ]]
  game_id=${BASH_REMATCH[3]}
  sets=${BASH_REMATCH[5]}
  set1=$(echo "$sets" | cut -f 1 -d '|' | trim)
  set2=$(echo "$sets" | cut -f 2 -d '|' | trim)
  num_matches=$(join <(echo "$set1" | tr ' ' "\n" | sort -b) <(echo "$set2" | tr ' ' "\n" | sort -b) | wc -l | trim)
  score=$([[ "$num_matches" -gt 0 ]] && (echo "2^(${num_matches}-1)" | bc -l) || echo "0")
  total_score=$((total_score+score))
done < $input_file

echo $total_score
