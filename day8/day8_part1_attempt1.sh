#!/usr/bin/env bash

input_file=$1
db_file=$2

[ -e "$db_file" ] && rm "$db_file"

duckdb $db_file "create table edges(v1 text, v2 text, label text)"

path=$(head -n1 < $input_file)

max_visits=${3:-$((${#path}*10))}
visit_incr=${4:-$((${#path}-1))}

while read -r vertex left right
do
  duckdb $db_file "insert into edges (v1, v2, label) values ('$vertex', '$left', 'L'), ('$vertex', '$right', 'R')"
done < <(grep '=' $input_file | sed 's/[^A-Z ]//g')

for ((i=$visit_incr; i<=$max_visits; i+=$visit_incr))
do
  num_visits=$(duckdb $db_file -readonly -csv -noheader <<EOF
    with recursive paths(start_v, end_v, path, num_visits) as (
      SELECT
        v1 as start_v,
        v2 as end_v,
        label as path,
        1 as num_visits
      FROM edges
      UNION ALL
      SELECT DISTINCT
          paths.start_v as start_v,
          edges.v2 as end_v,
          path || edges.label as path,
          paths.num_visits + 1 as num_visits
      FROM paths
      JOIN edges ON edges.v1 = paths.end_v
      WHERE num_visits <= $i
  )
  SELECT num_visits
  FROM paths
  WHERE start_v = 'AAA' and end_v = 'ZZZ' and regexp_matches(path, '^($path)+$')
  ORDER BY num_visits
  LIMIT 1
EOF
)
  if [[ $num_visits -gt 0 ]]
  then
    echo $num_visits
    break
  else
    echo "No valid paths found after $i visits. Trying again with $((i+visit_incr)) visits..."
  fi
done
