#!/bin/bash

# this script downloads all the aqua-faang ATAC peak files from salmobase

downloadPeakFiles() {
  LIST_URL="$1"
  BASE_URL=$(dirname $LIST_URL)
  # get list of files from the trackDb file. 
  # Get all ATAC .narrowPeak files (excluding Gill)
  # Download all of them
  curl -s "$LIST_URL" | grep -e "^bigDataUrl .*ATAC.*bigNarrowPeak$" | grep -v "Gill" |\
    sed "s|bigDataUrl |$BASE_URL|; s|\.bigNarrowPeak$|\.narrowPeak|" |\
    while IFS= read -r file_url; do
      echo Downloading $file_url
      curl -O "$file_url"
    done
}


OUTDIR="downloads/AtlanticSalmon-ATAC-peaks"
mkdir -p $OUTDIR

cd $OUTDIR
downloadPeakFiles "https://salmobase.org/datafiles/datasets/Aqua-Faang/trackhub/AtlanticSalmon/DevMap/trackDb.txt"
downloadPeakFiles "https://salmobase.org/datafiles/datasets/Aqua-Faang/trackhub/AtlanticSalmon/BodyMap/trackDb.txt"
cd -