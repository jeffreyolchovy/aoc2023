#!/usr/bin/env bash

input_file=$1

function trim() {
  awk '{$1=$1;print}'
}

declare -A game_scores

while read -r line
do
  [[ $line =~ ^(Card)( +)([0-9]+)(: )(.*)$ ]]
  game_id=${BASH_REMATCH[3]}
  sets=${BASH_REMATCH[5]}
  set1=$(echo "$sets" | cut -f 1 -d '|' | trim)
  set2=$(echo "$sets" | cut -f 2 -d '|' | trim)
  num_matches=$(join <(echo "$set1" | tr ' ' "\n" | sort -b) <(echo "$set2" | tr ' ' "\n" | sort -b) | wc -l | trim)
  game_scores+=([$game_id]=$num_matches)
done < $input_file

tmp_file=$(mktemp)
seq 1 ${#game_scores[@]} >> $tmp_file
while read -r line
do
  score=${game_scores[$line]}
  if [[ "$score" -ne 0 ]]
  then
    seq $((line+1)) $((line+score)) >> $tmp_file
  fi
done < $tmp_file

i=$(wc -l $tmp_file | trim | cut -f 1 -d ' ')
echo $i
