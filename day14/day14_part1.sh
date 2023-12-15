#!/usr/bin/env bash

input_file=$1

function transpose() {
  awk -v FS="" -v OFS="" '{for (i=1;i<=NF;i++) o[i]=(i in o ? o[i] OFS : "") $i;} END {for (i=1;i<=NF;i++) print o[i]}'
}

function tilt() {
  input=$1
  buf=
  for (( i=0; i<${#input}; i++ ))
  do
    tail=${input:$i}
    tail_head=${tail:0:1}
    case $tail_head in
      ".")
        [[ $tail =~ ^(\.)?(\.*)(O)?(.*$) ]]
        input=${input:0:i}${BASH_REMATCH[3]}${BASH_REMATCH[1]}${BASH_REMATCH[2]}${BASH_REMATCH[4]}
        buf=$input
        ;;
    esac
  done
  echo $buf
}

declare -a buf
while read -r line
do
  buf+=($(tilt $line))
done < <(transpose < $input_file)

buf_size=${#buf[@]}
i=$buf_size
n=0
while read -r line
do
  while read -rn1 char
  do
    [[ $char == "O" ]] && n=$((n+=i))
  done < <(echo -n "$line")
  i=$((i-1))
done < <(echo ${buf[@]} | tr ' ' "\n" | transpose)
echo $n
