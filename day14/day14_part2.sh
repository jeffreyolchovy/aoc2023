#!/usr/bin/env bash

input_file=$1
num_cycles=${2:-1}

function rot() {
  awk -v FS="" -v OFS="" '
    { if (max_nf < NF)
        max_nf = NF
      max_nr = NR
      for (x=1; x<=NF; x++)
        vector[x, NR] = $x
    }
    END {
      for (x = 1; x <= max_nf; x++) {
        for (y = max_nr; y >= 1; --y)
          printf("%s%s", vector[x, y], OFS)
        printf("\n")
      }
    }'
}

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
declare -a buf2

while read -r line
do
  buf+=($line)
done < $input_file

for (( i=1; i<=$num_cycles; i++ ))
do
  printf "cycle $i\r"
  for j in $(seq 1 4)
  do
    while read -r line
    do
      buf2+=($(tilt $line))
    done < <(echo ${buf[@]} | tr ' ' "\n" | transpose)

    buf=($(echo ${buf2[@]} | tr ' ' "\n" | transpose | tr "\n" ' '))
    unset buf2

    buf=($(echo ${buf[@]} | tr ' ' "\n" | rot | tr "\n" ' '))

    [[ $j -eq 4 ]] && break
  done
done

echo

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
done < <(echo ${buf[@]} | tr ' ' "\n")

echo $n
