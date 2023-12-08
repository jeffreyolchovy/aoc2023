#!/usr/bin/env bash

input_file=$1
db_file=$2

[ -e "$db_file" ] && rm "$db_file"

duckdb $db_file "create table hands(hand text, bid int, type text, ord_id text)"

declare -a cards=('A' 'K' 'Q' 'J' 'T' '9' '8' '7' '6' '5' '4' '3' '2')
declare -a ords=($(jot -w %c ${#cards[@]} a | tr "\n" ' '))
declare -A card_ord_map

for i in ${!cards[@]}
do
  card_ord_map[${cards[$i]}]=${ords[$i]}
done

function sort_chars() {
  echo $1 | grep -o . | sort | tr -d "\n"
}

function get_hand_type() {
  sorted_ord_id=$1
  echo $sorted_ord_id | pcregrep -q '^(?=.{5}$)^([a-m])\1\1\1\1$'
  if [[ $? -eq 0 ]]
  then
    echo "a (five of a kind)"
    return
  fi
  echo $sorted_ord_id | pcregrep -q '^(?=.{5}$)^.?([a-m])\1\1\1.?$'
  if [[ $? -eq 0 ]]
  then
    echo "b (four of a kind)"
    return
  fi
  echo $sorted_ord_id | pcregrep -q '^(?=.{5}$)^([a-m])\1\1?([a-m])\2\2?$'
  if [[ $? -eq 0 ]]
  then
    echo "c (full house)"
    return
  fi
  echo $sorted_ord_id | pcregrep -q '^(?=.{5}$)^.?.?([a-m])\1\1.?.?$'
  if [[ $? -eq 0 ]]
  then
    echo "d (three of a kind)"
    return
  fi
  echo $sorted_ord_id | pcregrep -q '^(?=.{5}$)^.?([a-m])\1.?([a-m])\2.?$'
  if [[ $? -eq 0 ]]
  then
    echo "e (two pair)"
    return
  fi
  echo $sorted_ord_id | pcregrep -q '^(?=.{5}$)^.?.?.?([a-m])\1.?.?.?$'
  if [[ $? -eq 0 ]]
  then
    echo "f (one pair)"
    return
  fi
  echo "g (high card)"
}

function get_hand_ord_id() {
  hand=$1
  while read -n1 char
  do
    printf "%s" ${card_ord_map[$char]}
  done < <(echo -n "$hand")
  printf "\n"
}

while read -r hand bid note
do
  ord_id=$(get_hand_ord_id $hand)
  hand_type=$(get_hand_type $(sort_chars $ord_id))
  echo "hand: $hand, bid: $bid, hand_type: $hand_type, ord_id: $ord_id, note: $note"
  duckdb $db_file "insert into hands (hand, bid, type, ord_id) values ('$hand', $bid, '$hand_type', '$ord_id')"
done < $input_file

duckdb $db_file -readonly -csv -noheader "select sum(bid * number) from (select *, ROW_NUMBER() OVER (ORDER BY type desc, ord_id desc) AS number from hands)"
