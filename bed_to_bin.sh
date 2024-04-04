#!/bin/bash


# make a file called "bed_list_test.txt" listing all bed file paths (one per line):
#find $OUTDIR -name "*.narrowPeak" > bed_list_test.txt
source activate explainn
# make bins: default 200 bin width and seq length 1000
binify_bed.py \
  --bedlist bed_list_test.txt \
  --fasta downloads/genome/Salmo_salar.Ssal_v3.1.dna_sm.toplevel.fa \
  --outfile AS-TAC_100bp.tsv \
  --exclude data/blacklist/AtlanticSalmon_blacklist_sorted.bed



echo "Create training/validation splits (percent = 90/10)"
# Get sequences
grep -v "^>" AS-TAC_100bp.tsv | cut -c 2- > ./AI-TAC/AI-TAC_sequences.txt
#Get peak ids
tail -n +2 ../tutorial/AI-TAC/mouse_peak_heights.csv | cut -d "," -f 1 \
> ./AI-TAC/AI-TAC_ids.txt
#Get peak heights
tail -n +2 ../tutorial/AI-TAC/mouse_peak_heights.csv | cut -d "," -f 2- | \
tr "," "\t" > ./AI-TAC/AI-TAC_heights.txt
#### Make binary peak heigths
awk -v OFS="\t" '{for(i=1; i<=NF; i++) if($i > 2) $i=1; else $i=0} 1' ./AI-TAC/AI-TAC_heights.txt > ./AI-TAC/AI-TAC_binary_heights.txt


paste -d "\t" ./AI-TAC/AI-TAC_ids.txt ./AI-TAC/AI-TAC_sequences.txt \
./AI-TAC/AI-TAC_binary_heights.txt > AI-TAC/AI-TAC_251bp.tsv
awk 'BEGIN {srand()} {f = FILENAME (rand() <= 0.1 ? ".validation" : ".train");
print > f}' ./AI-TAC/AI-TAC_251bp.tsv
