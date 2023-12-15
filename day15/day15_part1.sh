#!/usr/bin/env bash

input_file=$1

sum=0
while read -r word
do
  echo $word
  while read -rn 1 char
  do
    tmp=$((tmp+$(echo -n "$char" | od -An -tuC)))
    tmp=$((tmp*17))
    tmp=$((tmp % 256))
  done < <(echo -n "$word")
  sum=$((sum+tmp))
  unset tmp
done < <(tr ',' "\n" < $input_file)
echo $sum
