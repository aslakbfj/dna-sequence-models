#!/bin/bash

#SBATCH --output=./slurm/bed_to_bin%j_%a.log # Stdout and stderr file

# activate env such that python etc is available
source activate explainn
echo "environment activated"

script_dir=$PWD #path of binify_bed.py 
SALMON_FOLDER=/mnt/SCRATCH/asfj/downloads/genomes/salmon #where the salmon download is located
DATA_FOLDER=/mnt/SCRATCH/asfj/AS-TAC #where you want to store the entire bed file
HOME_DATA=/mnt/users/asfj/Thesis/data/salmon #where you want to store the training and validation files

# make a file called "bed_list_test.txt" listing all bed file paths (one per line):
cd $SALMON_FOLDER
echo "creating bed_list_test.txt"
find AS-TAC-peaks -name "*.narrowPeak" > bed_list_test.txt


# make bins: default 200 bin width and seq length 1000
echo "running python script"
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

echo "moving test/train files to HOME directory"
mv ./AS-TAC_1000bp.tsv.train $HOME_DATA/AS-TAC_1000bp.train.tsv
mv  ./AS-TAC_1000bp.tsv.validation $HOME_DATA/AS-TAC_1000bp.validation.tsv

#just testing
date -d @${SLURM_SUBMIT_TIMESTAMP}
echo $date