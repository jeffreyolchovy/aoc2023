#!/usr/bin/env bash

input_file=$1

current_x=0
current_y=0

declare -a points=("0,0")
while read -r line
do
  read -r dir dist hex < <(echo $line)
  case $dir in
    "L")
      current_x=$((current_x-dist))
      ;;
    "R")
      current_x=$((current_x+dist))
      ;;
    "U")
      current_y=$((current_y-dist))
      ;;
    "D")
      current_y=$((current_y+dist))
      ;;
  esac
  points+=("$current_x,$current_y")
done < $input_file

points_buf='POLYGON(('
last_i=$((${#points[@]}-1))
for i in ${!points[@]}
do
  IFS=, read -r x y < <(echo ${points[$i]})
  points_buf="$points_buf$x $y"
  [[ $i -ne $last_i ]] && points_buf="$points_buf, "
done
points_buf="$points_buf))"

duckdb -csv -noheader <<EOF
  install spatial;
  load spatial;
  select (((ia*2)+p)/2+1)::int from (
    select st_perimeter(st_geomfromtext('$points_buf')) as p, st_area(st_geomfromtext('$points_buf')) as ia
  )
EOF
