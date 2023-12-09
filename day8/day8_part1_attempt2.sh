#!/usr/bin/env bash

input_file=$1
db_file=$2

[ -e "$db_file" ] && rm "$db_file"

duckdb $db_file "create table edges(v1 text, v2 text, label text)"

path=$(head -n1 < $input_file)

while read -r vertex left right
do
  duckdb $db_file "insert into edges (v1, v2, label) values ('$vertex', '$left', 'L'), ('$vertex', '$right', 'R')"
done < <(grep '=' $input_file | sed 's/[^A-Z ]//g')

start="AAA"
end="ZZZ"
next=$start
path_traveled=
num_visits=0
is_complete=0
while [[ $is_complete -eq 0 ]]
do
  path_offset=$((num_visits % ${#path}))
  read -r next path_traveled num_visits < <(duckdb $db_file -readonly -csv -separator ' '  -noheader <<EOF
    select
      v2,
      '$path_traveled' || label as path,
      $num_visits + 1 as num_visits
    from edges
    where v1 = '$next'
    and label = '${path:$path_offset:1}'
EOF
  )
  if [[ $next == $end && $path_traveled =~ ($path)+ ]]
  then
    is_complete=1
    echo $num_visits
  fi
done
