#!/usr/bin/env bash

input_file=$1

function generate_combinations() {
  declare -a queue=($@)
  i=0
  while [[ ${queue[0]} == *"?"* ]]
  do
    head=${queue[0]}
    queue=("${queue[@]:1}")
    queue+=(${head/\?/#} ${head/\?/.})
    echo -en "\r$((i+=1))"
  done
  echo "${queue[@]}"
}

function count_spans() {
  declare -a counts
  n=0
  while read -rn1 char
  do
    case $char in
      "#")
        ((n+=1))
        ;;
      *)
        [[ $n -gt 0 ]] && counts+=($n)
        n=0
    esac
  done < <(echo "$1")
  echo "${counts[@]}"
}

# The runtimes of the pure shell solutions are abysmal...
# so, we'll shell out to simple Python routines
generate_combinations_py() {
  python - "$@" <<EOF
import sys
xs = [sys.argv[1]]
while "?" in xs[0]:
  x=xs.pop(0)
  xs.append(x.replace("?", "#", 1))
  xs.append(x.replace("?", ".", 1))
print(*xs, sep = "\n")
EOF
}

function count_spans_py() {
  python3 - "$@" <<EOF
import sys
from itertools import groupby
print(*[str(len(list(g))) for _, g in groupby(sys.argv[1]) if _ == '#'], sep = ' ')
EOF
}

# The runtime of this main loop is also abysmal...
# See day12_part1.py for a Python analogue
m=0
while read -r query expected
do
  expected=$(echo $expected | tr ',' ' ')
  n=0
  declare -a combinations=($(generate_combinations_py $query))
  for x in ${combinations[@]}
  do
    actual=$(count_spans_py $x)
    [[ $actual == $expected ]] && ((n+=1))
  done
  echo "$query has $n valid combinations"
  ((m+=n))
done < $input_file
echo $m
