#!/usr/bin/env bash

input_file=$1

function transpose() {
  awk -v FS="" -v OFS="" '{for (i=1;i<=NF;i++) o[i]=(i in o ? o[i] OFS : "") $i;} END {for (i=1;i<=NF;i++) print o[i]}'
}

function reflection_cols() {
  declare -A output
  input=$1
  input_size=${#input}

  from_left_col=
  for (( i=0; i<=$input_size; i++ ))
  do
    sub1=${input:$i:$input_size}
    sub1_size=${#sub1}
    if [[ $((sub1_size%2)) -eq 0 ]]
    then
      sub2=$(echo $sub1 | rev)
      if [[ $sub1 == $sub2 && $sub1_size -ge 2 ]]
      then
        from_left_col=$((i+(input_size-i)/2))
        output+=([$from_left_col]=1)
      fi
    fi
  done

  from_right_col=
  for (( i=1; i<$input_size; i++ ))
  do
    sub1=${input:0:$((-i))}
    sub1_size=${#sub1}
    if [[ $((sub1_size%2)) -eq 0 ]]
    then
      sub2=$(echo $sub1 | rev)
      if [[ $sub1 == $sub2 && $sub1_size -ge 1 ]]
      then
        from_right_col=$(((input_size-i)/2))
        output+=([$from_right_col]=1)
      fi
    fi
  done

  echo "${!output[@]}"
}

num_records=$(awk -v RS= '{s+=1} END {print s}' $input_file)

declare -a tmp_files
for i in $(seq 1 $num_records)
do
  tmp_files+=($(mktemp))
done

awk -v RS= -v tmp_files="${tmp_files[*]}" 'BEGIN {split(tmp_files, a)} {print > a[NR]}' $input_file

n=0
for f in ${tmp_files[@]}
do
  cat $f

  declare -a xs
  declare -a ys
  declare -a v_cols
  declare -a h_cols
  v_results=
  h_results=

  while read -r line
  do
    xs+=($line)
  done < $f

  for x in ${xs[@]}
  do
    v_cols+=($(reflection_cols $x))
  done
  xs_size=${#xs[@]}
  v_results=$(sort -n <(for n in ${v_cols[@]}; do echo $n; done) | uniq -c | sort -nr | grep -v "$xs_size " | head -n 1 | awk '{$1=$1;print}')
  if [[ $((xs_size - 1)) == $(echo $v_results | cut -f 1 -d ' ') ]]
  then
    m=$(echo $v_results | cut -f 2 -d ' ')
    echo "@ col $m"
    n=$((n+m))
  fi

  ys+=($(transpose < $f | tr "\n" ' '))
  for y in ${ys[@]}
  do
    h_cols+=($(reflection_cols $y))
  done
  ys_size=${#ys[@]}
  h_results=$(sort -n <(for n in ${h_cols[@]}; do echo $n; done) | uniq -c | sort -nr | grep -v "$ys_size " | head -n 1 | awk '{$1=$1;print}')
  if [[ $((ys_size - 1)) == $(echo $h_results | cut -f 1 -d ' ') ]]
  then
    m=$(echo $h_results | cut -f 2 -d ' ')
    echo "@ row $m"
    n=$((n+m*100))
  fi

  unset h_cols
  unset v_cols
  unset ys
  unset xs

  echo
done
echo $n
