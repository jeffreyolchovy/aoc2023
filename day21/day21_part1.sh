#!/usr/bin/env bash

input_file=$1
i=${2:-1}

rows_n=$(wc -l < $input_file | tr -d '[:space:]')
cols_n=$(head -n 1 < $input_file | tr -d "\n" | wc -c | tr -d '[:space:]')

start_coord=
declare -A valid_coords
declare -A edges

function neighbor() {
  IFS=, read -r col row < <(echo -n "$2")
  case $1 in
    "L")
      [[ $col -gt 0 ]] && echo "$((col-1)),$row"
      ;;
    "R")
      [[ $col -lt $((cols_n-1)) ]] && echo "$((col+1)),$row"
      ;;
    "T")
      [[ $row -gt 0 ]] && echo "$col,$((row-1))"
      ;;
    "B")
      [[ $row -lt $((rows_n-1)) ]] && echo "$col,$((row+1))"
      ;;
  esac
}

row=0
while read -r line
do
  col=0
  while read -rn 1 char
  do
    coord="$col,$row"
    case $char in
      "S")
        start_coord=$coord
        valid_coords+=([$coord]=1)
        ;;
      ".")
        valid_coords+=([$coord]=1)
        ;;
    esac
    ((col+=1))
  done < <(echo -n "$line")
  ((row+=1))
done < $input_file

for coord in ${!valid_coords[@]}
do
  declare -A neighbor_coords=(
    [L]=$(neighbor "L" $coord)
    [R]=$(neighbor "R" $coord)
    [T]=$(neighbor "T" $coord)
    [B]=$(neighbor "B" $coord))

  for dir in ${!neighbor_coords[@]}
  do
    neighbor_coord=${neighbor_coords[$dir]}
    [[ ! -z $neighbor_coord && -z ${valid_coords[$neighbor_coord]} ]] && unset neighbor_coords[$dir]
  done
  edges+=([$coord]="${neighbor_coords[@]}")
done

declare -a queue=($start_coord)

for i in $(seq 1 $i)
do
  declare -A next_coords=()

  for coord in ${queue[@]}
  do
    declare -a edge_coords=(${edges[$coord]})
    for next_coord in ${edge_coords[@]}
    do
      next_coords+=([$next_coord]=1)
    done
  done

  queue=(${!next_coords[@]})
done

echo ${#queue[@]}
