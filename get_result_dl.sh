lm_list=`cat lm_decode_list`

query_list="eval2000.ctm.filt.dtl eval2000.ctm.swbd.filt.dtl eval2000.ctm.callhm.filt.dtl"
dir_list="exp/tri4a exp_deeplearn/spn_tri4a_110h"
dir_names="Kaldi SPN-CNN"
#dir_list="exp/tri4a exp_deeplearn/spn_tri4a"

for query_file in $query_list; do 
echo -e "\n\n=====================Results from $query_file==========================="
       
        for dir in $dir_names; do
        echo -ne "$dir\t"
        done
        echo -e "Language Model"

	for lm in $lm_list; do
		#echo $trial
		#dir=exp_deeplearn/spn_tri4a/decode_$lm
		for dir in $dir_list; do
			dir2=$dir/decode_eval2000_$lm
			if [ -d $dir2 ]; then
				WER=
				WER=`grep 'Percent Total Error' $dir2/score_*/$query_file | sort -k5 -g | head -1 | awk '{print $5}' 2>/dev/null`;
				if [ -n "$WER" ]; then
				echo -ne  "$WER\t"
				else 
				echo -ne "null\t"
				fi
			else
			echo -ne "NA\t"
			fi
			
		done
		echo -e "$lm"
	done

done

#echo -e $tmp







