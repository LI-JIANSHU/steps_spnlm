#!/bin/bash

# this script is to be run after run.sh

while true; do
    read -p "This script is to be run after ./run.sh. Continue?" yn
    case $yn in
        [Yy]* ) echo "Continuing..."; 
		break;;
        [Nn]* ) echo "Exiting..";
		exit 1
 		break;;
        * ) echo "Please answer yes or no.";;
    esac
done


. cmd.sh
. path.sh
set -e # exit on error

if [ $# -ne 1 ]; then
  echo Usage: $0 path/to/new.arpa.gz;
  exit 1;
fi


new_arpa=$1

base_name=$(basename "$new_arpa" .arpa.gz)

dir=data/local/lm
cp $new_arpa $dir/

LM=data/local/lm/${base_name}.arpa.gz
spnlm_step/format_lm_spn.sh data/lang $LM data/local/dict/lexicon.txt data/lang_${base_name}



decoding_list="${base_name}"


for lm_suffix in $decoding_list; do
  (
    graph_dir=exp/tri1/graph_${lm_suffix}
    $train_cmd $graph_dir/mkgraph.log \
      utils/mkgraph.sh data/lang_${lm_suffix} exp/tri1 $graph_dir
    steps/decode_si.sh --nj 30 --cmd "$decode_cmd" --config conf/decode.config \
      $graph_dir data/eval2000 exp/tri1/decode_eval2000_${lm_suffix}
  ) 
done


for lm_suffix in $decoding_list; do
  (
    # The previous mkgraph might be writing to this file.  If the previous mkgraph
    # is not running, you can remove this loop and this mkgraph will create it.
    while [ ! -s data/lang_${lm_suffix}/tmp/CLG_3_1.fst ]; do sleep 60; done
    sleep 20; # in case still writing.
    graph_dir=exp/tri2/graph_${lm_suffix}
    $train_cmd $graph_dir/mkgraph.log \
      utils/mkgraph.sh data/lang_${lm_suffix} exp/tri2 $graph_dir
    steps/decode.sh --nj 30 --cmd "$decode_cmd" --config conf/decode.config \
      $graph_dir data/eval2000 exp/tri2/decode_eval2000_${lm_suffix}
  ) 
done


for lm_suffix in $decoding_list; do
  (
    graph_dir=exp/tri3b/graph_${lm_suffix}
    $train_cmd $graph_dir/mkgraph.log \
      utils/mkgraph.sh data/lang_${lm_suffix} exp/tri3b $graph_dir
    steps/decode.sh --nj 30 --cmd "$decode_cmd" --config conf/decode.config \
      $graph_dir data/eval2000 exp/tri3b/decode_eval2000_${lm_suffix}
  ) 
done


for lm_suffix in $decoding_list; do
  (
    graph_dir=exp/tri4a/graph_${lm_suffix}
    $train_cmd $graph_dir/mkgraph.log \
      utils/mkgraph.sh data/lang_${lm_suffix} exp/tri4a $graph_dir
    steps/decode_fmllr.sh --nj 30 --cmd "$decode_cmd" --config conf/decode.config \
      $graph_dir data/eval2000 exp/tri4a/decode_eval2000_${lm_suffix}
  ) 
done



#local/run_resegment.sh

# Now train a LDA+MLLT+SAT model on the entire training data (train_nodup; 
# 286 hours)
# Train tri4b, which is LDA+MLLT+SAT, on train_nodup data.

for lm_suffix in $decoding_list; do
  (
    graph_dir=exp/tri4b/graph_${lm_suffix}
    $train_cmd $graph_dir/mkgraph.log \
      utils/mkgraph.sh data/lang_${lm_suffix} exp/tri4b $graph_dir
    steps/decode_fmllr.sh --nj 30 --cmd "$decode_cmd" --config conf/decode.config \
       $graph_dir data/eval2000 exp/tri4b/decode_eval2000_${lm_suffix}
    steps/decode_fmllr.sh --nj 30 --cmd "$decode_cmd" --config conf/decode.config \
       $graph_dir data/train_dev exp/tri4b/decode_train_dev_${lm_suffix}
  ) 
done
wait


echo The trials \for 110h and 300h setup are finished
exit 1


# 4 iterations of MMI seems to work well overall. The number of iterations is
# used as an explicit argument even though train_mmi.sh will use 4 iterations by
# default.
num_mmi_iters=4

for iter in 1 2 3 4; do
  for lm_suffix in $decoding_list; do
    (
      graph_dir=exp/tri4a/graph_${lm_suffix}
      decode_dir=exp/tri4a_mmi_b0.1/decode_eval2000_${iter}.mdl_${lm_suffix}
    steps/decode.sh --nj 30 --cmd "$decode_cmd" --config conf/decode.config \
    --iter $iter --transform-dir exp/tri4a/decode_eval2000_${lm_suffix} \
            $graph_dir data/eval2000 $decode_dir
  ) 
  done
done

for iter in 1 2 3 4; do
  for lm_suffix in $decoding_list; do
    (
      graph_dir=exp/tri4b/graph_${lm_suffix}
      decode_dir=exp/tri4b_mmi_b0.1/decode_eval2000_${iter}.mdl_${lm_suffix}
      steps/decode.sh --nj 30 --cmd "$decode_cmd" --config conf/decode.config \
    --iter $iter --transform-dir exp/tri4b/decode_eval2000_${lm_suffix} \
    $graph_dir data/eval2000 $decode_dir   
  ) 
  done
done



for iter in 4 5 6 7 8; do
  for lm_suffix in $decoding_list; do
    (
      graph_dir=exp/tri4a/graph_${lm_suffix}
      decode_dir=exp/tri4a_fmmi_b0.1/decode_eval2000_it${iter}_${lm_suffix}
      steps/decode_fmmi.sh --nj 30 --cmd "$decode_cmd" --iter $iter \
	--transform-dir exp/tri4a/decode_eval2000_${lm_suffix} \
	--config conf/decode.config $graph_dir data/eval2000 $decode_dir
    ) 
  done
done

for iter in 4 5 6 7 8; do
  for lm_suffix in $decoding_list; do
    (
      graph_dir=exp/tri4b/graph_${lm_suffix}
      decode_dir=exp/tri4b_fmmi_b0.1/decode_eval2000_it${iter}_${lm_suffix}
      steps/decode_fmmi.sh --nj 30 --cmd "$decode_cmd" --iter $iter \
	--transform-dir exp/tri4b/decode_eval2000_${lm_suffix} \
	--config conf/decode.config $graph_dir data/eval2000 $decode_dir
    ) 
  done
done


