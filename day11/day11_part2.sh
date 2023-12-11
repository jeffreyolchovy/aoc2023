#!/usr/bin/env bash

input_file=$1
scale=${2:-0}

declare -a empty_rows
declare -a empty_cols
declare -a coords
declare -A distances

function transpose() {
  awk -v FS="" -v OFS="" '{for (i=1;i<=NF;i++) o[i]=(i in o ? o[i] OFS : "") $i;} END {for (i=1;i<=NF;i++) print o[i]}'
}

function find_empty_rows() {
  awk "/^\.+\$/ {print NR-1}"
}

function order_coords() {
  echo -e "$1\n$2" | sort -nk 1,2 -t ',' | tr "\n" ' '
}

function manhattan_dist() {
  declare -a coord_1=($(echo $1 | tr ',' ' '))
  declare -a coord_2=($(echo $2 | tr ',' ' '))

  row_crossings=0
  col_crossings=0

  for i in "${empty_rows[@]}"
  do
    [[ ($i -gt ${coord_1[1]} && $i -lt ${coord_2[1]}) || ($i -lt ${coord_1[1]} && $i -gt ${coord_2[1]}) ]] &&
      row_crossings=$((row_crossings+1))
  done

  for i in "${empty_cols[@]}"
  do
    [[ ($i -gt ${coord_1[0]} && $i -lt ${coord_2[0]}) || ($i -lt ${coord_1[0]} && $i -gt ${coord_2[0]}) ]] &&
      col_crossings=$((col_crossings+1))
  done

  delta_rows=$((${coord_1[1]} - ${coord_2[1]}))
  delta_rows=$((${delta_rows#-} + row_crossings * scale))

  delta_cols=$((${coord_1[0]} - ${coord_2[0]}))
  delta_cols=$((${delta_cols#-} + col_crossings * scale))

  echo $((delta_rows + delta_cols))
}

empty_rows=($(find_empty_rows < $input_file | tr "\n" ' '))
empty_cols=($(transpose < $input_file | find_empty_rows | tr "\n" ' '))

row=0
while read -r line
do
  col=0
  while read -rn1 char
  do
    case $char in
      "#") coords+=("$col,$row") ;;
      *) ;;
    esac
    col=$((col+1))
  done < <(echo -n "$line")
  row=$((row+1))
done < $input_file

for ((i=0; i<${#coords[@]}; i+=1))
do
  for ((j=0; j<${#coords[@]}; j+=1))
  do
    [ $i -eq $j ] && break
    coord_1=${coords[$i]}
    coord_2=${coords[$j]}
    ordered_coords=$(order_coords $coord_1 $coord_2)
    ordered_coords_i=$(echo "$ordered_coords" | tr ' ' '->')
    if [[ -z ${distances[$ordered_coords_i]} ]]
    then
      distances+=([$ordered_coords_i]=$(manhattan_dist $ordered_coords))
    fi
  done
done

n=0
for i in ${distances[@]}
do
  n=$((n+i))
done
echo $n
