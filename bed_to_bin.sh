#!/bin/bash



source activate explainn
# make bins: default 200 bin width and seq length 1000
SALMON_FOLDER=/mnt/SCRATCH/asfj/downloads/genomes/salmon

# make a file called "bed_list_test.txt" listing all bed file paths (one per line):
cd $SALMON_FOLDER
find AS-TAC-peaks -name "*.narrowPeak" > bed_list_test.txt

binify_bed.py \
  --bedlist bed_list_test.txt \
  --fasta genome/Salmo_salar.Ssal_v3.1.dna_sm.toplevel.fa \
  --outfile AS-TAC_1000bp.tsv \
  --seq_length 1000 \
  --exclude blacklist/AtlanticSalmon_blacklist_sorted.bed



# echo "Create training/validation splits (percent = 90/10)"
# # Get sequences
# grep -v "^>" AS-TAC_1000bp.tsv | cut -c 2- > ./AS-TAC/AS-TAC_sequences.txt
# #Get peak ids
# tail -n +2 ../tutorial/AI-TAC/mouse_peak_heights.csv | cut -d "," -f 1 \
# > ./AI-TAC/AI-TAC_ids.txt
# #Get peak heights
# tail -n +2 ../tutorial/AI-TAC/mouse_peak_heights.csv | cut -d "," -f 2- | \
# tr "," "\t" > ./AI-TAC/AS-TAC_heights.txt

# paste -d "\t" ./AI-TAC/AI-TAC_ids.txt ./AI-TAC/AI-TAC_sequences.txt \
# ./AI-TAC/AI-TAC_binary_heights.txt > AI-TAC/AI-TAC_1000bp.tsv

awk 'BEGIN {srand()} {f = FILENAME (rand() <= 0.1 ? ".validation" : ".train");
print > f}' ./AS-TAC_1000bp.tsv
