#!/bin/bash


# Begin configuration section.
# end configuration sections

help_message="Usage: "`basename $0`" [options] lang_dir LM lexicon out_dir
Convert ARPA-format language models to FSTs. Change the LM vocabulary using SRILM.\n
options: 
  --help                 # print this message and exit
";

. utils/parse_options.sh

if [ $# -ne 4 ]; then
  printf "$help_message\n";
  exit 1;
fi

lang_dir=$1
lm=$2
lexicon=$3
out_dir=$4
mkdir -p $out_dir

[ -f ./path.sh ] && . ./path.sh


echo "Converting '$lm' to FST"
tmpdir=$(mktemp -d kaldi.XXXX);
trap 'rm -rf "$tmpdir"' EXIT

for f in phones.txt words.txt L.fst L_disambig.fst phones/; do
  cp -r $lang_dir/$f $out_dir || exit 1;
done

lm_base=$(basename $lm '.gz')
gunzip -c $lm | utils/find_arpa_oovs.pl $out_dir/words.txt \
  > $out_dir/oovs_${lm_base}.txt || exit 1;

awk '{print $1}' $out_dir/words.txt > $tmpdir/voc || exit 1;

cp $lm $tmpdir/
gunzip $tmpdir/$lm_base.gz || exit 1;

arpa2fst $tmpdir/$lm_base | fstprint \
  | utils/eps2disambig.pl | utils/s2eps.pl \
  | fstcompile --isymbols=$out_dir/words.txt --osymbols=$out_dir/words.txt \
    --keep_isymbols=false --keep_osymbols=false \
  | fstrmepsilon > $out_dir/G.fst || exit 1;

fstisstochastic $out_dir/G.fst

# The output is like:
# 9.14233e-05 -0.259833
# we do expect the first of these 2 numbers to be close to zero (the second is
# nonzero because the backoff weights make the states sum to >1).

# Everything below is only for diagnostic.
# Checking that G has no cycles with empty words on them (e.g. <s>, </s>);
# this might cause determinization failure of CLG.
# #0 is treated as an empty word.
mkdir -p $out_dir/tmpdir.g
awk '{if(NF==1){ printf("0 0 %s %s\n", $1,$1); }} 
     END{print "0 0 #0 #0"; print "0";}' \
     < "$lexicon" > $out_dir/tmpdir.g/select_empty.fst.txt || exit 1;

fstcompile --isymbols=$out_dir/words.txt --osymbols=$out_dir/words.txt \
  $out_dir/tmpdir.g/select_empty.fst.txt \
  | fstarcsort --sort_type=olabel \
  | fstcompose - $out_dir/G.fst > $out_dir/tmpdir.g/empty_words.fst || exit 1;

fstinfo $out_dir/tmpdir.g/empty_words.fst | grep cyclic | grep -w 'y' \
  && echo "Language model has cycles with empty words" && exit 1

rm -r $out_dir/tmpdir.g


echo "Succeeded in formatting LM: '$lm'"
