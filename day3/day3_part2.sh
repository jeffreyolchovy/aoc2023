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

sqlite3 $db_file "create table star_matches (num integer, star_id text);"
for ((i=0; i<${#num_spans[@]}; i++))
do
  num=${num_spans[$i]}
  row_addr=${num_spans_row_address[$i]}
  col_addr=${num_spans_col_address[$i]}
  col_addr2=$((col_addr+${#num}-1))
  sqlite3 $db_file <<EOF
    insert into star_matches
    select $num, row || ',' || col as star_id from (
      select * from chars
      where
       (row = $row_addr - 1 AND (col >= $col_addr-1 AND col <= $col_addr2+1))
      or
       (row = $row_addr AND (col = $col_addr-1 OR col = $col_addr2+1))
      or
       (row = $row_addr + 1 AND (col >= $col_addr-1 AND col <= $col_addr2+1))
    )
    where value = '*';
EOF
done

exprs=$(sqlite3 $db_file <<EOF
  select group_expr from (
    select star_id, group_concat(num, '*') as group_expr, count(1) as group_size
    from star_matches group by star_id having group_size = 2
  );
EOF
)

sum_exprs=0
while read -r expr
do
  sum_exprs=$((sum_exprs+$((expr))))
done < <(echo "$exprs")

echo $sum_exprs
