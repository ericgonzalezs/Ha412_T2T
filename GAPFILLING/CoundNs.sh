#!/bin/bash

fasta=$1

samtools faidx $fasta

# Output header
echo -e "chromosome\tgap_start\tgap_end\tgap_length"

# Loop over each chromosome name from FASTA index
cut -f1 "$fasta.fai" | while read chr; do
    samtools faidx "$fasta" "$chr" | \
    awk -v chr="$chr" '
    BEGIN { seq = "" }
    /^>/ { next }         # skip fasta header
    { seq = seq $0 }      # concatenate lines into sequence
    END {
        in_gap = 0
        for (i = 1; i <= length(seq); i++) {
            c = substr(seq, i, 1)
            if (c == "N" || c == "n") {
                if (!in_gap) {
                    start = i
                    in_gap = 1
                }
            } else {
                if (in_gap) {
                    end = i - 1
                    len = end - start + 1
                    printf "%s\t%d\t%d\t%d\n", chr, start, end, len
                    in_gap = 0
                }
            }
        }
        if (in_gap) {
            end = i - 1
            len = end - start + 1
            printf "%s\t%d\t%d\t%d\n", chr, start, end, len
        }
    }'
done
