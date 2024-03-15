# DNA sequence models

**work in progress**

This repo currently contain scripts for preparing training data for ML models that genomic sequences.

"download_from_salmobase.sh" - downloads peak files, blacklist file and fasta file

"binify_bed.py" - reads multiple bed files (with non-overlapping regions) and divides it into bins of certain size (default: 200) and outputs the bins where atleast one of the files had a peak that overlaps the bin with more than a given number of bases (default 50% of bin). The sequence for that bin is also extracted from a given fasta file.


Example:

```{sh}
python3 binify_bed.py \
  --bedlist bed_list_test.txt \
  --fasta downloads/genome/Salmo_salar.Ssal_v3.1.dna_sm.toplevel.fa \
  --outfile test.tsv \
  --exclude data/blacklist/AtlanticSalmon_blacklist_sorted.bed \
  --seq_length 10
```

where "bed_list_test.txt" contains paths to peak files (one per line):

```
downloads/AtlanticSalmon-ATAC-peaks/AtlanticSalmon_ATAC_LateBlastulation_R1.mLb.clN_peaks.narrowPeak
downloads/AtlanticSalmon-ATAC-peaks/AtlanticSalmon_ATAC_LateSomitogenesis_R1.mLb.clN_peaks.narrowPeak
downloads/AtlanticSalmon-ATAC-peaks/AtlanticSalmon_ATAC_Brain_Immature_Female_R1.mLb.clN_peaks.narrowPeak
downloads/AtlanticSalmon-ATAC-peaks/AtlanticSalmon_ATAC_Liver_Immature_Female_R1.mLb.clN_peaks.narrowPeak
downloads/AtlanticSalmon-ATAC-peaks/AtlanticSalmon_ATAC_Muscle_Immature_Female_R1.mLb.clN_peaks.narrowPeak
downloads/AtlanticSalmon-ATAC-peaks/AtlanticSalmon_ATAC_Gonad_Mature_Female_R1.mLb.clN_peaks.narrowPeak
downloads/AtlanticSalmon-ATAC-peaks/AtlanticSalmon_ATAC_Gonad_Mature_Male_R1.mLb.clN_peaks.narrowPeak
```

The output file is a .tsv file with columns:

* binID: currently shows the region of the extracted sequence
* sequence: extracted sequence (Note: may contain N's)
* values: one for each file. 1 if peak overlaps 0 if not

```
1:444096-444105 ACACAAACAA      1       1       1       1       0       0       0
```



