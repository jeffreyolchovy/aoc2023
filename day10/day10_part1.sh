#!/usr/bin/env bash

input_file=$1
edges_file=$(mktemp)

grid_rows_n=$(wc -l < $input_file | tr -d '[:space:]')
grid_cols_n=$(head -n 1 < $input_file | tr -d "\n" | wc -c | tr -d '[:space:]')

function get_dirs() {
  case $1 in
    "|") echo "N S" ;;
    "-") echo "E W" ;;
    "L") echo "N E" ;;
    "J") echo "N W" ;;
    "7") echo "S W" ;;
    "F") echo "S E" ;;
    *) ;;
  esac
}

function get_coord() {
  row=$1
  col=$2
  case $3 in
    "N") [[ $row -eq 0 ]] && echo "$((grid_rows_n-1)),$col" || echo "$((row-1)),$col" ;;
    "S") [[ $row -eq $((grid_rows_n-1)) ]] && echo "0,$col" || echo "$((row+1)),$col" ;;
    "W") [[ $col -eq 0 ]] && echo "$row,$((grid_cols_n-1))" || echo "$row,$((col-1))" ;;
    "E") [[ $col -eq $((grid_cols_n-1)) ]] && echo "$row,0" || echo "$row,$((col+1))" ;;
    *) ;;
  esac
}

row=0
while read -r line
do
  col=0
  while read -rn1 char
  do
    case $char in
      "|"|"-"|"L"|"J"|"7"|"F")
        dirs=($(get_dirs $char))
        coord="$row,$col"
        coord_1=$(get_coord $row $col ${dirs[0]})
        coord_2=$(get_coord $row $col ${dirs[1]})
        echo "$coord $coord_1" >> $edges_file
        echo "$coord $coord_2" >> $edges_file
        ;;
      "S")
         s_row=$row
         s_col=$col
         s_coord="$row,$col"
         ;;
      *) ;;
    esac
    col=$((col+1))
  done < <(echo -n "$line")
  row=$((row+1))
done < $input_file

declare -a viable_chars
while read -rn1 char
do
  dirs=($(get_dirs $char))
  coord_1=$(get_coord $s_row $s_col ${dirs[0]})
  coord_2=$(get_coord $s_row $s_col ${dirs[1]})
  matching_edges=$(grep -E "^($coord_1|$coord_2) $s_coord$" $edges_file | wc -l | tr -d "[:space:]")
  if [[ $matching_edges -eq 2 ]]
  then
    echo "$char is viable for S @ $s_coord"
    viable_chars+=($char)
  fi
done < <(echo -n "|-LJ7F")

for char in "${viable_chars[@]}"
do
  declare -A distances
  echo "Evaluating $char as replacement for S"
  dirs=($(get_dirs $char))
  prev_1=$s_coord
  prev_2=$s_coord
  next_1=$(get_coord $s_row $s_col ${dirs[0]})
  next_2=$(get_coord $s_row $s_col ${dirs[1]})
  distance=1
  distances+=([$s_coord]=0 [$next_1]=$distance [$next_2]=$distance)
  while [[ $cycle -eq 0 ]]
  do
    current_1=$next_1
    current_2=$next_2
    next_1=$(grep -E "^$current_1 " $edges_file | grep -vE " $prev_1$" | cut -f 2 -d ' ')
    next_2=$(grep -E "^$current_2 " $edges_file | grep -vE " $prev_2$" | cut -f 2 -d ' ')
    prev_1=$current_1
    prev_2=$current_2

    distance=$((distance+1))

    distance_1=${distances[$next_1]}
    if [[ -z $distance_1 ]]
    then
      distances+=([$next_1]=$distance)
      cycle=0
    else
      distances+=([$next_1]=$((distance_1 < distance ? distance_1 : distance)))
      cycle=1
    fi

    distance_2=${distances[$next_2]}
    if [[ -z $distance_2 ]]
    then
      distances+=([$next_2]=$distance)
      cycle=0
    else
      distances+=([$next_2]=$((distance_2 < distance ? distance_2 : distance)))
      cycle=1
    fi
  done

  furthest_distance=$(echo "${distances[@]}" | tr ' ' "\n" | sort -nr | head -n 1)
  echo "The furthest distance from S is $furthest_distance (when S as $char)"
done
