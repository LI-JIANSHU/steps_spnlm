lm_list="sw1_tg sw1_fsh_tgpr"

trial_list="
exp/tri1/decode_eval2000_ 
exp/tri2/decode_eval2000_ 
exp/tri3b/decode_eval2000_  
exp/tri4a/decode_eval2000_ 
exp/tri4a_fmmi_b0.1/decode_eval2000_it4_
exp/tri4a_fmmi_b0.1/decode_eval2000_it5_
exp/tri4a_fmmi_b0.1/decode_eval2000_it6_
exp/tri4a_fmmi_b0.1/decode_eval2000_it7_
exp/tri4a_fmmi_b0.1/decode_eval2000_it8_
exp/tri4a_mmi_b0.1/decode_eval2000_1.mdl_
exp/tri4a_mmi_b0.1/decode_eval2000_2.mdl_
exp/tri4a_mmi_b0.1/decode_eval2000_3.mdl_
exp/tri4a_mmi_b0.1/decode_eval2000_4.mdl_
exp/tri4b/decode_eval2000_ 
exp/tri4b_fmmi_b0.1/decode_eval2000_it4_
exp/tri4b_fmmi_b0.1/decode_eval2000_it5_
exp/tri4b_fmmi_b0.1/decode_eval2000_it6_
exp/tri4b_fmmi_b0.1/decode_eval2000_it7_
exp/tri4b_fmmi_b0.1/decode_eval2000_it8_
exp/tri4b_mmi_b0.1/decode_eval2000_1.mdl_
exp/tri4b_mmi_b0.1/decode_eval2000_2.mdl_
exp/tri4b_mmi_b0.1/decode_eval2000_3.mdl_
exp/tri4b_mmi_b0.1/decode_eval2000_4.mdl_
"

query_list="eval2000.ctm.filt.dtl eval2000.ctm.swbd.filt.dtl eval2000.ctm.callhm.filt.dtl"
for query_file in $query_list; do 
echo -e "\n\n=====================Results from $query_file==========================="

tmp=
for lm in $lm_list; do
tmp=$tmp"\t"$lm
done
echo -e $tmp

for trial in $trial_list; do
tmp=
	for lm in $lm_list; do
		dir=$trial$lm	
		if [ -d $dir ]; then
			WER=`grep 'Percent Total Error' $dir/score_*/$query_file | sort -k5 -g | head -1 | awk '{print $5}' 2>/dev/null`;
			tmp=$tmp"\t"$WER
		else tmp=$tmp"\tNA"
		fi
	done

tmp=$tmp"\t"$trial
echo -e $tmp
done

done



