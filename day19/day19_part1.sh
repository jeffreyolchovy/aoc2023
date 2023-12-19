#!/usr/bin/env bash

input_file=$1

declare -a records

function parse_workflow_instructions() {
  id=$1
  i=$2
  [[ $3 =~ ([xmas][<>][0-9]+):([^,]+),?(.*)? ]]
  op=${BASH_REMATCH[1]}
  if_true=${BASH_REMATCH[2]}
  if_false=${BASH_REMATCH[3]}
  eval "$id+=([$i]='$op')"
  eval "$id+=([$((2*i))]='$if_true')"
  [[ $if_false =~ ^[AR]?|[a-z]+$ ]]
  if [[ -n ${BASH_REMATCH[0]} ]]
  then
    eval "$id+=([$((2*i+1))]='$if_false')"
  else
    parse_workflow_instructions $id $((2*i+1)) $if_false
  fi
}

function eval_workflow_node() {
  id=$1
  i=$2
  record=$3
  IFS=, read -r x m a s < <(echo $record)
  node_value=$(eval echo '${'$id'['$i']}')
  case $node_value in
    "R")
      echo 0
      ;;
    "A")
      echo $((x+m+a+s))
      ;;
    *"<"*|*">"*)
      result=$(($node_value))
      if [[ $result -eq 1 ]]
      then
        eval_workflow_node $id $((2*i)) $record
      else
        eval_workflow_node $id $((2*i+1)) $record
      fi
      ;;
    *)
      eval_workflow_node $node_value 1 $record
      ;;
  esac
}

parse_wfs=1
parse_records=0
while read -r line
do
  if [[ ${#line} -eq 0 ]]
  then
    parse_wfs=0
    parse_records=1
    continue
  fi

  if [[ $parse_wfs -eq 1 ]]
  then
    [[ $line =~ ([a-z]+){(.*)} ]]
    wf_id=${BASH_REMATCH[1]}
    wf_instructions=${BASH_REMATCH[2]}
    eval "declare -a $wf_id"
    parse_workflow_instructions $wf_id 1 $wf_instructions
  elif [[ $parse_records -eq 1 ]]
  then
    records+=("$(echo $line | tr -cd '0-9,')")
  fi
done < $input_file

n=0
for record in ${records[@]}
do
  result=$(eval_workflow_node "in" 1 $record)
  n=$((n+result))
done
echo $n
