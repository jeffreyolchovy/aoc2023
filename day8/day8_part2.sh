#!/usr/bin/env bash

input_file=$1
db_file=$2

[ -e "$db_file" ] && rm "$db_file"

duckdb $db_file "create table edges(v1 text, v2 text, label text)"

path=$(head -n1 < $input_file)

while read -r vertex left right
do
  duckdb $db_file "insert into edges (v1, v2, label) values ('$vertex', '$left', 'L'), ('$vertex', '$right', 'R')"
done < <(grep '=' $input_file | sed 's/[^0-9A-Z ]//g')

function quote() {
  sed "s/^/'/;s/$/'/"
}

vertices=$(duckdb $db_file -readonly -csv -noheader "select distinct v1 from edges where v1 like '%A'")
num_as=$(echo "$vertices" | wc -l)
path_traveled=
num_visits=0
declare -A z_vertex_visits
while :
do
  path_offset=$((num_visits % ${#path}))
  direction=${path:$path_offset:1}
  vertices=$(duckdb $db_file -readonly -csv -noheader <<EOF
    select distinct
      v2
    from edges
    where v1 in ($(echo "$vertices" | sed "s/^/'/;s/$/'/" | paste -s -d ',' -))
    and label = '$direction'
EOF
  )
  path_traveled="$path_traveled$direction"
  num_visits=$((num_visits+1))
  num_zs=$(echo "$vertices" | grep "Z$" | wc -l)

  if [[ $path_offset -eq 0 ]]
  then
    echo "visit: $num_visits"
  fi

  if [[ $num_zs -gt 0 ]]
  then
    for v in $(echo "$vertices" | grep "Z$")
    do
      if [ -z ${z_vertex_visits[$v]} ]
      then
        z_vertex_visits+=([$v]=$num_visits)
        echo "$v vertex visited @ $num_visits"
      fi
    done
  fi

  if [[ $num_as -eq ${#z_vertex_visits[@]} ]]
  then
    echo "All 'Z$' verticies visited @:"
    echo "${z_vertex_visits[@]}"

    lcm=1
    for n in "${z_vertex_visits[@]}"
    do
      lcm=$(duckdb $db_file -readonly -csv -noheader "select lcm($lcm, $n)")
    done
    echo "LCM of 'Z$' visits: $lcm"

    break
  fi
done
