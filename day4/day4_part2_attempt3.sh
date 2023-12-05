#!/usr/bin/env bash

input_file=$1
n_procs=${2:-1}

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

declare -a tmp_files

for i in $(seq 0 $((n_procs-1)))
do
  tmp_file=$(mktemp)
  echo "Created temporary file $tmp_file for shard $i"
  tmp_files+=($tmp_file)
done

for i in $(seq 1 ${#game_scores[@]})
do
  shard=$((i % n_procs))
  echo "$i" >> ${tmp_files[$shard]}
done

function process_shard() {
  tmp_file=$1
  echo "Processing shard of input @ $tmp_file"
  while read -r line
  do
    score=${game_scores[$line]}
    if [[ "$score" -ne 0 ]]
    then
      seq $((line+1)) $((line+score)) >> $tmp_file
    fi
  done < $tmp_file
}

for i in $(seq 0 $(($n_procs-1)))
do
  process_shard ${tmp_files[$i]} &
done

wait

n=0
for ((i=0; i<${#tmp_files[@]}; i++))
do
  m=$(wc -l ${tmp_files[$i]} | trim | cut -f 1 -d ' ')
  n=$((n+m))
done

echo $n
