#!/bin/bash


# make a file called "bed_list_test.txt" listing all bed file paths (one per line):
find $OUTDIR -name "*.narrowPeak" > bed_list_test.txt

# make bins: default 200 bin width and seq length 1000
python3 binify_bed.py \
  --bedlist bed_list_test.txt \
  --fasta downloads/genome/Salmo_salar.Ssal_v3.1.dna_sm.toplevel.fa \
  --outfile AtlanticSalmon_bins.tsv \
  --exclude data/blacklist/AtlanticSalmon_blacklist_sorted.bed
  