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
  local id=$1
  local i=$2
  local xmin=${3:-1}
  local xmax=${4:-4000}
  local mmin=${5:-1}
  local mmax=${6:-4000}
  local amin=${7:-1}
  local amax=${8:-4000}
  local smin=${9:-1}
  local smax=${10:-4000}
  local node_value=$(eval echo '${'$id'['$i']}')
  local operand_1=
  local operand_2=
  local min_tmp=
  local max_tmp=
  case $node_value in
    "R")
      echo 0
      ;;
    "A")
      echo $xmin $xmax $mmin $mmax $amin $amax $smin $smax
      ;;
    *">"*|*"<"*)
      operand_1=${node_value:0:1}
      eval "min_tmp=\$${operand_1}min"
      eval "max_tmp=\$${operand_1}max"
      ;;&
    *">"*)
      operand_2=${node_value#*>}
      eval ${operand_1}min=$((operand_2+1))
      eval_workflow_node $id $((2*i)) $xmin $xmax $mmin $mmax $amin $amax $smin $smax

      eval "${operand_1}min=$min_tmp"
      eval ${operand_1}max=$((operand_2))
      eval_workflow_node $id $((2*i+1)) $xmin $xmax $mmin $mmax $amin $amax $smin $smax
      ;;
    *"<"*)
      operand_2=${node_value#*<}
      eval ${operand_1}max=$((operand_2-1))
      eval_workflow_node $id $((2*i)) $xmin $xmax $mmin $mmax $amin $amax $smin $smax

      eval "${operand_1}max=$max_tmp"
      eval ${operand_1}min=$((operand_2))
      eval_workflow_node $id $((2*i+1)) $xmin $xmax $mmin $mmax $amin $amax $smin $smax
      ;;
    *)
      eval_workflow_node $node_value 1 $xmin $xmax $mmin $mmax $amin $amax $smin $smax
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
    parse_records=0
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
while read -r xmin xmax mmin mmax amin amax smin smax
do
  x=$([[ $xmax -gt $xmin ]] && echo $((xmax - xmin + 1)) || echo 0)
  m=$([[ $mmax -gt $mmin ]] && echo $((mmax - mmin + 1)) || echo 0)
  a=$([[ $amax -gt $amin ]] && echo $((amax - amin + 1)) || echo 0)
  s=$([[ $smax -gt $smin ]] && echo $((smax - smin + 1)) || echo 0)
  n=$((n+(x*m*a*s)))
done < <(eval_workflow_node "in" 1)
echo $n
