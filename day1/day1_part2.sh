#!/usr/bin/env bash

input_file=$1
n=0

function digitize() {
  case $1 in
    "one")    echo 1 ;;
    "two")    echo 2 ;;
    "three")  echo 3 ;;
    "four")   echo 4 ;;
    "five")   echo 5 ;;
    "six")    echo 6 ;;
    "seven")  echo 7 ;;
    "eight")  echo 8 ;;
    "nine")   echo 9 ;;
    [0-9])    echo $1 ;;
  esac
}

while read -r line
do
  [[ $line =~ (one|two|three|four|five|six|seven|eight|nine|[0-9]) ]]
  first_extract=${BASH_REMATCH[1]}
  reversed_line=$(echo $line | rev)
  [[ $reversed_line =~ (enin|thgie|neves|xis|evif|ruof|eerht|owt|eno|[0-9]) ]]
  last_extract=$(echo ${BASH_REMATCH[1]} | rev)
  first_digit=$(digitize $first_extract)
  last_digit=$(digitize $last_extract)
  incr="$first_digit$last_digit"
  n=$((n+incr))
done < $input_file

echo $n
