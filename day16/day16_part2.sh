#!/usr/bin/env bash

input_file=$1

rows_n=$(wc -l < $input_file | tr -d '[:space:]')
cols_n=$(head -n 1 < $input_file | tr -d "\n" | wc -c | tr -d '[:space:]')

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

declare -A coord_values

row=0
while read -r line
do
  col=0
  while read -rn 1 char
  do
    coord="$col,$row"
    coord_values+=([$coord]=$char)
    ((col++))
  done < <(echo -n "$line")
  ((row++))
done < $input_file

function calc() {
  declare -a queue=($1)
  declare -A coord_visited
  while [[ ${#queue[@]} -gt 0 ]]
  do
    head=${queue[0]}
    queue=("${queue[@]:1}")
    IFS=, read -r dir col row < <(echo -n "$head")
    coord="$col,$row"
    [[ ${coord_visited[$coord]} =~ $dir ]]
    visited=${BASH_REMATCH[0]}
    if [[ -z $visited && $col -ge 0 && $col -lt $cols_n && $row -ge 0 && $row -lt $rows_n ]]
    then
      coord_visited+=([$coord]="${coord_visited[$coord]}$dir")
      l_neighbor=$(neighbor "L" $coord)
      r_neighbor=$(neighbor "R" $coord)
      t_neighbor=$(neighbor "T" $coord)
      b_neighbor=$(neighbor "B" $coord)

      case ${coord_values[$coord]} in
        "."|"-")
          case $dir in
            "L") [[ ! -z $r_neighbor ]] && queue+=("L,$r_neighbor") ;;
            "R") [[ ! -z $l_neighbor ]] && queue+=("R,$l_neighbor") ;;
          esac
          ;;&
        "."|"|")
          case $dir in
            "T") [[ ! -z $b_neighbor ]] && queue+=("T,$b_neighbor") ;;
            "B") [[ ! -z $t_neighbor ]] && queue+=("B,$t_neighbor") ;;
          esac
          ;;&
        "-")
          case $dir in
            "T"|"B")
              [[ ! -z $r_neighbor ]] && queue+=("L,$r_neighbor")
              [[ ! -z $l_neighbor ]] && queue+=("R,$l_neighbor")
              ;;
          esac
          ;;
        "|")
          case $dir in
            "L"|"R")
              [[ ! -z $b_neighbor ]] && queue+=("T,$b_neighbor")
              [[ ! -z $t_neighbor ]] && queue+=("B,$t_neighbor")
              ;;
          esac
          ;;
        "/")
          case $dir in
            "L") [[ ! -z $t_neighbor ]] && queue+=("B,$t_neighbor") ;;
            "R") [[ ! -z $b_neighbor ]] && queue+=("T,$b_neighbor") ;;
            "T") [[ ! -z $l_neighbor ]] && queue+=("R,$l_neighbor") ;;
            "B") [[ ! -z $r_neighbor ]] && queue+=("L,$r_neighbor") ;;
          esac
          ;;
        "\\")
          case $dir in
            "L") [[ ! -z $b_neighbor ]] && queue+=("T,$b_neighbor") ;;
            "R") [[ ! -z $t_neighbor ]] && queue+=("B,$t_neighbor") ;;
            "T") [[ ! -z $r_neighbor ]] && queue+=("L,$r_neighbor") ;;
            "B") [[ ! -z $l_neighbor ]] && queue+=("R,$l_neighbor") ;;
          esac
          ;;
      esac
    fi
  done
  echo ${#coord_visited[@]}
}

declare -a results
for i in $(seq 0 $((cols_n-1)))
do
  results+=($(calc "T,$i,0"))
  results+=($(calc "B,$i,$((rows_n-1))"))
done
for i in $(seq 0 $((rows_n-1)))
do
  results+=($(calc "L,0,$i"))
  results+=($(calc "R,$((cols_n-1)),$i"))
done

max=
for n in ${results[@]}
do
  [[ $n -gt $max ]] && max=$n
done
echo $max
