# I am using yahs --version
#1.2.2
#After running juicer, we going to use the file merged_nodups.txt to create a bed file for yahs
#####################################################################################################


awk '
{
     if ($9 > 0 && $12 > 0) {
    # Calculate end position for read 1 using pos1 and cigar1
    cigar = $10
    pos_start1 = $3
    sum1 = 0
    while (match(cigar, /([0-9]+)([MDNX=])/, arr)) {
        sum1 += arr[1]
        cigar = substr(cigar, RSTART + RLENGTH)
    }
    pos_end1 = pos_start1 + sum1  # End position for read 1

    # Calculate end position for read 2 using pos2 and cigar2
    cigar = $13
    pos_start2 = $7
    sum2 = 0
    while (match(cigar, /([0-9]+)([MDNX=])/, arr)) {
        sum2 += arr[1]
        cigar = substr(cigar, RSTART + RLENGTH)
    }
    pos_end2 = pos_start2 + sum2  # End position for read 2

    # Print interleaved output for read 1 and read 2
    print $2, pos_start1, pos_end1, $15"/1", $9
    print $6, pos_start2, pos_end2, $16"/2", $12
}
}
' merged_nodups.txt > merged_nodups_for_yahs.bed

#######################################################################################
#now we going to run yahs like this:


export PATH=$PATH:/DATA/home/egonzalez/SOFTWARE/YAHS/yahs

samtools faidx purged.fa

yahs purged.fa merged_nodups_for_yahs.bed

##############################################################################################
###Now we going to create our hic and assembly file to observe it in Juicebox
#########################


module load StdEnv/2020 python/3.11.2 java/17.0.2 lastz/1.04.03

juicer pre -a -o out_JBAT yahs.out.bin yahs.out_scaffolds_final.agp purged.fa.fai >out_JBAT.log 2>&1

(java -jar -Xmx240G /DATA/home/egonzalez/SOFTWARE/JUICER/juicer/CPU/common/juicer_tools.1.9.9_jcuda.0.8.jar pre out_JBAT.txt out_JBAT.hic.part <(cat out_JBAT.log  | grep PRE_C_SIZE | awk '{print $2" "$3}')) && (mv out_JBAT.hic.part out_JBAT.hic)
