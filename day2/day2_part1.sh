#!/usr/bin/env bash

input_file=$1
db_file=$2

> $db_file
sqlite3 $db_file "create table games (id integer, round integer, blue integer default 0, green integer default 0, red integer default 0);"

while read -r line
do
  [[ $line =~ ^(Game )([0-9]+)(: )(.*)$ ]]
  game_id=${BASH_REMATCH[2]}
  rounds=${BASH_REMATCH[4]}
  round_id=1
  while read -r round
  do
    sqlite3 $db_file "insert into games (id, round) values ($game_id, $round_id);"
    while read -r draw
    do
      [[ $draw =~ ^([0-9]+)( )(red|green|blue)$ ]]
      color=${BASH_REMATCH[3]}
      value=${BASH_REMATCH[1]}
      sqlite3 $db_file  "update games set $color=$value where id=$game_id and round=$round_id;"
    done < <(echo $round | tr ',' "\n" | awk '{$1=$1;print}')
    round_id=$((round_id+1))
  done < <(echo $rounds | tr ';' "\n" | awk '{$1=$1;print}')
done < $input_file

sqlite3 $db_file "select sum(distinct id) from games where id not in (select distinct id from games where red > 12 or green > 13 or blue > 14);"
