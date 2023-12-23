#!/usr/bin/env bash

input_file=$1

declare -A brick_ids
declare -A brick_coords
declare -a coords_d
declare -A edges_u
declare -A edges_d

while read line
do
  IFS=, read x1 y1 z1 x2 y2 z2 label < <(echo $line)
  id=${label:-$line}
  brick_ids+=([$id]=1)

  coords_d=()

  while [[ $z1 -gt 1 && ${#coords_d[@]} -eq 0 ]]
  do
    for ((x=$x1; x<=$x2; x++)); do for ((y=$y1; y<=$y2; y++)); do for ((z=$z1; z<=$z2; z++)); do
      k="$x,$y,$((z-1))"
      [[ ! -z ${brick_coords[$k]} ]] && coords_d+=($k)
    done; done; done
    [[ ${#coords_d[@]} -eq 0 ]] && z1=$((z1-1)) && z2=$((z2-1))
  done

  for ((x=$x1; x<=$x2; x++)); do for ((y=$y1; y<=$y2; y++)); do for ((z=$z1; z<=$z2; z++)); do
    k="$x,$y,$z"
    brick_coords+=([$k]=$id)
  done; done; done

  for k in ${coords_d[@]}
  do
    for id2 in ${brick_coords[$k]}
    do
      ids=${edges_u[$id2]}
      [[ ! $ids =~ $id ]] && edges_u+=([$id2]="$ids $id")
      ids2=${edges_d[$id]}
      [[ ! $ids2 =~ $id2 ]] && edges_d+=([$id]="$ids2 $id2")
    done
  done
done < <(tr '~' ',' < $input_file | sort -nk 3 -t ,)

eval declare -A candidates=(${brick_ids[@]@K})

for id in ${!candidates[@]}
do
  for id2 in ${edges_u[$id]}
  do
    declare -a ids=(${edges_d[$id2]})
    [[ ${#ids[@]} -eq 1 ]] && unset candidates[$id] && break
  done
done

echo ${#candidates[@]}
