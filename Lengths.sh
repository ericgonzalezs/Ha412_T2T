#!/bin/bash

fasta=$1

awk '
     /^>/ {
         if (seqlen) {print header, seqlen}   # print previous header + length
         header=$0                            # store new header
         seqlen=0                             # reset length counter
         next
     }
     { seqlen += length($0) }                 # add up sequence length
     END { print header, seqlen }             # print last record
 ' $fasta
