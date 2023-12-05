#!/usr/bin/env bash

input_file=$1
db_file=$2

> $db_file
sqlite3 $db_file "create table chars (row integer, col integer, value text);"

declare -a num_spans
declare -a num_spans_row_address
declare -a num_spans_col_address

in_num_span=0
current_num_span=
row=1
while read -r line
do
  col=1
  while read -rn1 char
  do
    sqlite3 $db_file "insert into chars (row, col, value) values ($row, $col, '$char');"
    case $char in
      [0-9])
        if [[ $in_num_span -eq 0 ]]
        then
          num_spans_row_address+=($row)
          num_spans_col_address+=($col)
        fi
        in_num_span=1
        current_num_span="$current_num_span$char"
        ;;
      *)
        if [[ $in_num_span -eq 1 ]]
        then
          num_spans+=($current_num_span)
        fi
        in_num_span=0
        current_num_span=
        ;;
    esac
    col=$((col+1))
  done < <(echo -n "$line")
  row=$((row+1))
done < $input_file

sum_matched_nums=0
for ((i=0; i<${#num_spans[@]}; i++))
do
  num=${num_spans[$i]}
  row_addr=${num_spans_row_address[$i]}
  col_addr=${num_spans_col_address[$i]}
  col_addr2=$((col_addr+${#num}-1))
  is_match=$(sqlite3 $db_file <<EOF
    with neighbors as (
      select * from chars
      where
       (row = $row_addr - 1 AND (col >= $col_addr-1 AND col <= $col_addr2+1))
      or
       (row = $row_addr AND (col = $col_addr-1 OR col = $col_addr2+1))
      or
       (row = $row_addr + 1 AND (col >= $col_addr-1 AND col <= $col_addr2+1))
    )
    select count(1) from neighbors
    where value <> '.';
EOF
  )

  if [[ "$is_match" -ne "0" ]]
  then
    sum_matched_nums=$((sum_matched_nums+num))
  fi
done

echo $sum_matched_nums
