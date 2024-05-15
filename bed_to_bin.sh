#!/bin/bash

#SBATCH --output=./slurm/bed_to_bin%j_%a.log # Stdout and stderr file

# activate env such that python etc is available
source activate explainn
echo "environment activated"

script_dir=$PWD #path of binify_bed.py 
SALMON_FOLDER=/mnt/SCRATCH/asfj/downloads/genomes/salmon #where the salmon download is located
DATA_FOLDER=/mnt/SCRATCH/asfj/AS-TAC #where you want to store the tsv files
HOME_DATA=/mnt/users/asfj/Thesis/data/salmon #where you want to store the training and validation files

# make and if statement to check if the file exists
if [ -f $HOME_DATA/AS-TAC_1000bp.train.tsv ]; then
    echo "File exists"
else
    echo "File does not exist"
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
fi

if [ -f $DATA_FOLDER/AS-TAC_21_25_test.tsv ]; then
  echo "21_25.tsv exists"
else
    # make a subset of AS-TAC_1000bp.tsv of lines where the first column starts with "21" or "25"
    echo "creating testsubset of AS-TAC_1000bp.tsv for 21_25 with all classes"
    awk '$1 ~ /^21|^25/' $DATA_FOLDER/AS-TAC_1000bp.tsv > $DATA_FOLDER/AS-TAC_21_25_test.tsv
    # make a subset of the data that did not contain 21 or 25
    echo "creating train subset of AS-TAC_1000bp.tsv for 21_25 with all classes"
    awk '$1 !~ /^21|^25/' $DATA_FOLDER/AS-TAC_1000bp.tsv > $DATA_FOLDER/AS-TAC_21_25_train.tsv
fi


# If $DATA_FOLDER/AS-TAC_noMuscle_1000bp.tsv does not exist, do the next
if [ -f $DATA_FOLDER/AS-TAC_noMuscle_1000bp.tsv ]; then
  echo "AS-TAC_noMuscle_1000bp.tsv exists"
else
  # Make other subsets of the data, where we remove classes 
  echo "creating subset of AS-TAC_1000bp.tsv without Muscle"
  cd $SALMON_FOLDER
  # remove all lines that contain "Muscle", "Gonad_Immature_Female_R2" or "Gonad_Mature_Male_R2" from bed_list_full.txt, and remove the corresponding columns from each line of AS-TAC_1000bp.tsv
  awk '$0 !~ /Muscle/' bed_list_full.txt \
  | awk '$0 !~ /Gonad_Immature_Female_R2/' \
  | awk '$0 !~ /Gonad_Mature_Male_R2/' > bed_list_noMuscle.txt

  # Make the new tsv with the new bed_list
  python $script_dir/binify_bed.py \
    --bedlist bed_list_noMuscle.txt \
    --fasta genome/Salmo_salar.Ssal_v3.1.dna_sm.toplevel.fa \
    --outfile $DATA_FOLDER/AS-TAC_noMuscle_1000bp.tsv \
    --seq_length 1000 \
    --exclude blacklist/AtlanticSalmon_blacklist_sorted.bed
fi

# If $DATA_FOLDER/AS-TAC_noMuscle_21_25_test.tsv does not exist, do the next
if [ -f $DATA_FOLDER/AS-TAC_noMuscle_21_25_test.tsv ]; then
  echo "AS-TAC_noMuscle_21_25_test.tsv exists"
else
  # make a subset of AS-TAC_noMuscle_1000bp.tsv of lines where the first column starts with "21" or "25"
  echo "creating subset of AS-TAC_noMuscle_1000bp.tsv"
  awk '$1 ~ /^21|^25/' $DATA_FOLDER/AS-TAC_noMuscle_1000bp.tsv > $DATA_FOLDER/AS-TAC_noMuscle_21_25_test.tsv
  # make a subset of the data that did not contain 21 or 25
  echo "creating subset of AS-TAC_noMuscle_1000bp.tsv"
  awk '$1 !~ /^21|^25/' $DATA_FOLDER/AS-TAC_noMuscle_1000bp.tsv > $DATA_FOLDER/AS-TAC_noMuscle_21_25_train.tsv
fi




############################# BED TO BIN FOR MERGED PEAKS ########################################

# If $DATA_FOLDER/AS-TAC_merged_1000bp.tsv does not exist, do the next
if [ -f $DATA_FOLDER/AS-TAC_merged_1000bp.tsv ]; then
  echo "AS-TAC_merged_1000bp.tsv exists"
else
  # make a file called "bed_list_merged.txt" listing all bed file paths, sorted (one per line):
  cd $SALMON_FOLDER
  echo "creating bed_list_merged.txt"
  find AS-TAC-merged_peaks -name "*.narrowPeak" | sort > bed_list_merged.txt

  # make bins: default 200 bin width and seq length 1000
  echo "running python script"
  python $script_dir/binify_bed.py \
    --bedlist bed_list_merged.txt \
    --fasta genome/Salmo_salar.Ssal_v3.1.dna_sm.toplevel.fa \
    --outfile $DATA_FOLDER/AS-TAC_merged_1000bp.tsv \
    --seq_length 1000 \
    --exclude blacklist/AtlanticSalmon_blacklist_sorted.bed
fi

# make a subset of AS-TAC_merged_1000bp.tsv of lines where the first column starts with "21" or "25"
if [ -f $DATA_FOLDER/AS-TAC_merged_21_25_test.tsv ]; then
  echo "AS-TAC_merged_21_25_test.tsv exists"
else
  echo "creating subset of AS-TAC_merged_1000bp.tsv for 21_25 with all classes"
  awk '$1 ~ /^21|^25/' $DATA_FOLDER/AS-TAC_merged_1000bp.tsv > $DATA_FOLDER/AS-TAC_merged_21_25_test.tsv
  # make a subset of the data that did not contain 21 or 25
  echo "creating subset of AS-TAC_merged_1000bp.tsv for 21_25 with all classes"
  awk '$1 !~ /^21|^25/' $DATA_FOLDER/AS-TAC_merged_1000bp.tsv > $DATA_FOLDER/AS-TAC_merged_21_25_train.tsv
fi