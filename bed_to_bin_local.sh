#!/bin/bash

# activate env such that python etc is available

script_dir=$PWD #path of binify_bed.py 
SALMON_FOLDER=./downloads #parent directory for AS-TAC, genome, blacklist
DATA_FOLDER=../../../SCRATCH/AS-TAC #where you want to store the entire bed file
HOME_DATA=../data/salmon #where you want to store the training and validation files

# make a file called "bed_list_test.txt" listing all bed file paths (one per line):
cd $SALMON_FOLDER
echo "creating bed_list_test.txt"
find AS-TAC-peaks -name "*.narrowPeak" > bed_list_test.txt


# make bins: default 200 bin width and seq length 1000
echo "running python script"

# run a script using the conda environment testy such that the modules load 
conda init
conda activate testy
python $script_dir/binify_bed.py \
  --bedlist bed_list_test.txt \
  --fasta genome/Salmo_salar.Ssal_v3.1.dna_sm.toplevel.fa \
  --outfile $DATA_FOLDER/AS-TAC_1000bp.tsv \
  --seq_length 1000 \
  --exclude blacklist/AtlanticSalmon_blacklist_sorted.bed



echo "creating training/validation splits"
cd $DATA_FOLDER
awk 'BEGIN {srand()} {f = FILENAME (rand() <= 0.1 ? ".validation" : ".train");
print > f}' ./AS-TAC_1000bp.tsv

echo "moving files"
#mv ./AS-TAC_1000bp.tsv.train $HOME_DATA/AS-TAC_1000bp.train.tsv
#mv  ./AS-TAC_1000bp.tsv.validation $HOME_DATA/AS-TAC_1000bp.validation.tsv