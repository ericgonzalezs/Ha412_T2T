#!/bin/bash

lengths=$1
gaps=$2

#awk '
 #    /^>/ {
  #       if (seqlen) {print header, seqlen}   # print previous header + length
   #      header=$0                            # store new header
   #      seqlen=0                             # reset length counter
   #      next
   #  }
   #  { seqlen += length($0) }                 # add up sequence length
   #  END { print header, seqlen }             # print last record
# ' Fakefasta.fasta > Fakefasta_names_lengths.txt


awk '
# ---- First file: gap table ----
NR==FNR {
    chr=$1
    start=$2
    end=$3
    gaplen=$4
    gaps[chr,++gapcount[chr]] = start ":" end ":" gaplen
    next
}

# ---- Second file: fasta header + length table ----
/^>/ {
    gsub(/^>/, "", $1)          # remove ">" for easier handling
    chr=$1
    seqlen=$2
    pos=1
    frag=0

    # If scaffold has gaps, split into fragments
    if (gapcount[chr] > 0) {
        for (i=1; i<=gapcount[chr]; i++) {
            split(gaps[chr,i], a, ":")
            gstart=a[1]; gend=a[2]; glen=a[3]

            if (pos < gstart) {
                frag++
                frag_global++
                fraglen=gstart-pos
                if(fraglen>0) print ">"chr":::fragment_"frag, frag_global, fraglen
            }

            frag++
            frag_global++
            print ">"chr":::fragment_"frag":::debris", frag_global, glen
            pos=gend+1
        }

        # Last piece after final gap
        if (pos <= seqlen) {
            frag++
            frag_global++
            fraglen=seqlen-pos+1
            if(fraglen>0) print ">"chr":::fragment_"frag, frag_global, fraglen
        }

    } else {
        # No gaps → print scaffold as-is
        frag_global++
        print ">"chr, frag_global, seqlen
    }
}
' $gaps $lengths

