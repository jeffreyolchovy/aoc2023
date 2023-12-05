#!/usr/bin/env bash

db_file=$1

sqlite3 $db_file "select sum(max_red * max_green * max_blue) from (select id, max(red) as max_red, max(green) as max_green, max(blue) as max_blue from games group by id);"
