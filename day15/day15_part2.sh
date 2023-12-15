#!/usr/bin/env bash

input_file=$1

declare -A buckets

while read -r word
do
  [[ $word =~ ([a-z]+)([=-])([0-9]+)? ]]
  label=${BASH_REMATCH[1]}
  operator=${BASH_REMATCH[2]}
  operand=${BASH_REMATCH[3]}

  while read -rn 1 char
  do
    k=$((k+$(echo -n "$char" | od -An -tuC)))
    k=$((k*17))
    k=$((k % 256))
  done < <(echo -n "$label")

  current=${buckets[$k]}
  case $operator in
    "-")
      next=$(echo $current | sed "s/$label [0-9][[:blank:]]*//")
      ;;
    "=")
      pattern="$label [0-9]"
      replacement="$label $operand"
      [[ -z $current ]] && next=$replacement || next=$([[ $current =~ $label ]] && echo "${current/$pattern/$replacement}" || echo "$current $replacement")
      ;;
  esac
  buckets+=([$k]=$next)
  unset k
done < <(tr ',' "\n" < $input_file)

sum=0
for k in ${!buckets[@]}
do
  i=1
  while read -r n
  do
    sum=$((sum+(k+1)*i*n))
    i=$((i+1))
  done < <(echo "${buckets[$k]}" | tr ' ' "\n" | grep -v "[a-z]" | grep -v "^[[:space:]]*$")
done
echo $sum
