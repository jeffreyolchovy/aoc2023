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

i=0
function f() {
  case $# in
    0)
      ;;
    *)
      i=$((i+1))
      head=$1
      shift
      tail="$@"
      score=${game_scores[$head]}
      if [[ "$score" -ne 0 ]]
      then
        tail_prepend=$(seq $((head+1)) $((head+score)) | tr "\n" ' ')
        tail=$(echo "$tail_prepend$tail")
      fi
      f $tail
      ;;
  esac
}

f $(seq 1 ${#game_scores[@]} | tr "\n" ' ')

echo $i
