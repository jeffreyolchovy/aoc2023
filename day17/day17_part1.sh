#!/usr/bin/env bash

input_file=$1

rows_n=$(wc -l < $input_file | tr -d '[:space:]')
cols_n=$(head -n 1 < $input_file | tr -d "\n" | wc -c | tr -d '[:space:]')

start_coord="0,0"
end_coord="$((cols_n-1)),$((rows_n-1))"

declare -A dir_swap=([L]=R [R]=L [T]=B [B]=T)

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

declare -A path

function h() {
  IFS=, read -r col row < <(echo $1)
  echo $((cols_n-col+rows_n-row))
}

function a_star() {
  declare -A open_set=(["$start_coord,,"]=1)

  declare -A came_from

  declare -A g_score=(["$start_coord,,"]=${coord_values[$start_coord]})

  declare -A f_score=(["$start_coord,,"]=$(h $start_coord $end_coord))

  while [[ ${#open_set[@]} -gt 0 ]]
  do
    min=
    for k in ${!open_set[@]}
    do
      if [[ -z $min || $min -gt ${f_score[$k]} ]]
      then
        min=${f_score[$k]}
        current_k=$k
      fi
    done

    IFS=, read -r current_col current_row current_dir current_streak < <(echo $current_k)
    current_coord="$current_col,$current_row"

    if [[ $current_coord == $end_coord ]]
    then
      parent=$current_k
      while [[ ! -z $parent ]]
      do
        IFS=, read -r parent_col parent_row parent_dir parent_streak < <(echo $parent)
        path+=(["$parent_col,$parent_row"]=1)
        child=$parent
        parent=${came_from[$child]}
      done
      break
    else
      unset open_set[$current_k]

      declare -A neighbor_coords=(
        [L]=$(neighbor "L" $current_coord)
        [R]=$(neighbor "R" $current_coord)
        [T]=$(neighbor "T" $current_coord)
        [B]=$(neighbor "B" $current_coord))

      if [[ ! -z $current_dir ]]
      then
        unset neighbor_coords[${dir_swap[$current_dir]}]
      fi

      if [[ ! -z $current_streak && $current_streak -eq 3 ]]
      then
        unset neighbor_coords[$current_dir]
      fi

      for next_dir in ${!neighbor_coords[@]}
      do
        next_coord=${neighbor_coords[$next_dir]}
        next_streak=$([[ $current_dir == $next_dir ]] && echo $((current_streak+1)) || echo 1)
        if [[ ! -z $next_coord ]]
        then
          next_k="$next_coord,$next_dir,$next_streak"
          tmp_g_score=$((${coord_values[$next_coord]}+${g_score[$current_k]}))
          if [[ -z ${g_score[$next_k]} || $tmp_g_score -lt ${g_score[$next_k]} ]]
          then
            came_from+=([$next_k]=$current_k)
            g_score+=([$next_k]=$tmp_g_score)
            f_score+=([$next_k]=$((tmp_g_score+$(h $next_coord $end_coord))))
            open_set+=([$next_k]=1)
          fi
        fi
      done
    fi
  done
}

a_star

bold=$(tput bold)
normal=$(tput sgr0)

n=0
for i in $(seq 0 $((rows_n-1)))
do
  for j in $(seq 0 $((cols_n-1)))
  do
    coord="$j,$i"
    value=${coord_values[$coord]}
    if [[ -z ${path[$coord]} ]]
    then
      printf "%s" $value
    else
      printf "$bold%s$normal" $value
      if [[ $coord != "0,0" ]]
      then
        n=$((n+value))
      fi
    fi
  done
  printf "\n"
done
echo $n
