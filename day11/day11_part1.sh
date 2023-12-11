#!/usr/bin/env bash

input_file=$1

declare -a coords
declare -A distances

function transpose() {
  awk -v FS="" -v OFS="" '{for (i=1;i<=NF;i++) o[i]=(i in o ? o[i] OFS : "") $i;} END {for (i=1;i<=NF;i++) print o[i]}'
}

function dupe_empty_row() {
  awk "/^\.+\$/ {print} 1"
}

function order_coords() {
  echo -e "$1\n$2" | sort -nk 1,2 -t ',' | tr "\n" ' '
}

function manhattan_dist() {
  declare -a coord_1=($(echo $1 | tr ',' ' '))
  declare -a coord_2=($(echo $2 | tr ',' ' '))
  delta_1=$((${coord_1[0]} - ${coord_2[0]}))
  delta_2=$((${coord_1[1]} - ${coord_2[1]}))
  echo $((${delta_1#-} + ${delta_2#-}))
}

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
done < <(dupe_empty_row < $input_file | transpose | dupe_empty_row | transpose)

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
