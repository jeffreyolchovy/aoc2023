#!/usr/bin/env bash

input_file=$1
i=${2:-1}

declare -a queue

declare -A dsts_by_src

declare -A cons

declare -A ffs

declare -A emit_counts=([L]=0 [H]=0)

while read -r line
do
  [[ $line =~ (.*)( -> )(.*) ]]
  src_id=${BASH_REMATCH[1]}
  dst_ks=${BASH_REMATCH[3]}

  case ${src_id:0:1} in
    "&")
      src_k=${src_id:1}
      cons+=([$src_k]="")
      ;;
    "%")
      src_k=${src_id:1}
      ffs+=([$src_k]="0")
      ;;
    *)
      src_k=$src_id
      ;;
  esac
  dsts_by_src+=([$src_k]=${dst_ks//, / })
done < $input_file

for con_k in ${!cons[@]}
do
  for src_k in ${!dsts_by_src[@]}
  do
    dst_ks=${dsts_by_src[$src_k]}
    [[ $dst_ks =~ $con_k ]] && {
      [[ -z ${cons[$con_k]} ]] && cons+=([$con_k]="$src_k,L") || cons+=([$con_k]="${cons[$con_k]} $src_k,L")
    }
  done
done

for src_k in ${!dsts_by_src[@]}
do
  dst_ks=${dsts_by_src[$src_k]}
  echo "$src_k -> $dst_ks"
done

echo

while [[ $i -gt 0 ]]
do
  ((i-=1))
  queue+=("button,L,broadcaster")

  while [[ ${#queue[@]} -gt 0 ]]
  do
    head=${queue[0]}
    queue=("${queue[@]:1}")
    IFS=, read -r sent_key sig recv_key < <(echo $head)

    echo "$sent_key -$sig-> $recv_key"

    sig_count=${emit_counts[$sig]}
    emit_counts+=([$sig]=$((sig_count+1)))

    declare -a dsts=(${dsts_by_src[$recv_key]})

    if [[ ! -z ${ffs[$recv_key]} ]]
    then
      state=${ffs[$recv_key]}
      case "$sig,$state" in
        *"H"*)
          unset emit_sig
          ;;
        *"L,0")
          ffs+=([$recv_key]="1")
          emit_sig="H"
          ;;&
        *"L,1")
          ffs+=([$recv_key]="0")
          emit_sig="L"
          ;;&
      esac
    elif [[ ! -z ${cons[$recv_key]} ]]
    then
      declare -a con_srcs=(${cons[$recv_key]})
      h_count=0
      for src in ${con_srcs[@]}
      do
        IFS=, read -r src_key src_sig < <(echo $src)
        if [[ $src_key == $sent_key ]]
        then
          con_srcs_tmp=${cons[$recv_key]}
          replacement=$src_key,$sig
          cons+=([$recv_key]=${con_srcs_tmp/$src/$replacement})
          src_sig=$sig
        fi
        [[ $src_sig == "H" ]] && h_count=$((h_count+1))
      done
      [[ ${#con_srcs[@]} -eq $h_count ]] && emit_sig="L" || emit_sig="H"
    else
      emit_sig=$sig
    fi

    if [[ ! -z $emit_sig ]]
    then
      for dst in ${dsts[@]}
      do
        queue+=("$recv_key,$emit_sig,$dst")
      done
    fi
  done

  echo "conjunction states:"
  for con_k in ${!cons[@]}
  do
    echo -e "\t$con_k <- ${cons[$con_k]}"
  done

  echo "flip-flop states:"
  for ff_k in ${!ffs[@]}
  do
    echo -e "\t$ff_k = ${ffs[$ff_k]}"
  done

  echo
done

n=1
for sig in ${!emit_counts[@]}
do
  count=${emit_counts[$sig]}
  echo "$count $sig signals emitted"
  n=$((n*count))
done
echo $n
