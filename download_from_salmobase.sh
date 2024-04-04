#!/bin/bash

# this script downloads all the aqua-faang ATAC peak files from salmobase

downloadPeakFiles() {
  LIST_URL="$1"
  BASE_URL=$(dirname $LIST_URL)
  # get list of files from the trackDb file. 
  # Get all ATAC .narrowPeak files (excluding Gill)
  # Download all of them
  curl -s "$LIST_URL" | grep -e "^bigDataUrl .*ATAC.*bigNarrowPeak$" | grep -v "Gill" |\
    sed "s|bigDataUrl |$BASE_URL/|; s|\.bigNarrowPeak$|\.narrowPeak|" |\
    while IFS= read -r file_url; do
      echo Downloading $file_url
      if ! curl -s -f -O "$file_url"; then
        echo "ERROR: Failed to download $file_url"
      fi
    done
}


OUTDIR=/mnt/SCRATCH/asfj/downloads/genomes/salmon/AS-TAC-peaks
mkdir -p $OUTDIR

cd $OUTDIR
downloadPeakFiles "https://salmobase.org/datafiles/datasets/Aqua-Faang/trackhub/AtlanticSalmon/DevMap/trackDb.txt"
downloadPeakFiles "https://salmobase.org/datafiles/datasets/Aqua-Faang/trackhub/AtlanticSalmon/BodyMap/trackDb.txt"
cd -

mkdir "blacklist"
curl https://salmobase.org/datafiles/datasets/Aqua-Faang/blacklist/AtlanticSalmon_blacklist.bed \
  -o blacklist/AtlanticSalmon_blacklist.bed

# sort the blacklist
mkdir -p "data/blacklist"
sort -k1,1 -k2,2n blacklist/AtlanticSalmon_blacklist.bed > data/blacklist/AtlanticSalmon_blacklist_sorted.bed

# download genome
mkdir -p "downloads/genome"
cd "downloads/genome"
curl -O "http://ftp.ensembl.org/pub/release-106/fasta/salmo_salar/dna/Salmo_salar.Ssal_v3.1.dna_sm.toplevel.fa.gz"
#gzip -d Salmo_salar.Ssal_v3.1.dna_sm.toplevel.fa.gz
cd -
