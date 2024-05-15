#!/bin/bash

# this script downloads all the aqua-faang ATAC peak files from salmobase

# make a list of Brain, Gonad, Liver, Muscle in bash language
tissues=("Brain" "Gonad" "Liver" "Muscle")
URL="https://salmobase.org/datafiles/datasets/Aqua-Faang/nfcore/AtlanticSalmon/BodyMap/ATAC/Brain/results/bwa/mergedReplicate/macs/narrowPeak/"

# Make a list with URLs for all tissues, bash language
URLs=()
for tissue in ${tissues[@]}; do
    URLs+=("https://salmobase.org/datafiles/datasets/Aqua-Faang/nfcore/AtlanticSalmon/BodyMap/ATAC/${tissue}/results/bwa/mergedReplicate/macs/narrowPeak/")
done

# Download all .narrowPeak files in each URL, saving all in the same directory, bash language
OUTDIR="/mnt/SCRATCH/asfj/downloads/genomes/salmon/AS-TAC-merged_peaks"

mkdir -p $OUTDIR
cd $OUTDIR
for URL in ${URLs[@]}; do
    curl -s $URL | grep -oP 'href="\K[^"]+' | grep -e "narrowPeak$" | while read -r file; do
        echo "Downloading $URL$file"
        curl -s -O $URL$file
    done
done

#Download all .narrowPeak from DevMap aswell
URL="https://salmobase.org/datafiles/datasets/Aqua-Faang/nfcore/AtlanticSalmon/DevMap/ATAC/results/bwa/mergedReplicate/macs/narrowPeak/"
curl -s $URL | grep -oP 'href="\K[^"]+' | grep -e "narrowPeak$" | while read -r file; do
    echo "Downloading $URL$file"
    curl -s -O $URL$file
done

# Make a list of all the files downloaded, save as .txt file with each line as a file name, sorted
ls -1 | sort > ../bed_list_merged.txt
