#These are the purge_dups steps I followed. More information can be found here: https://github.com/dfguan/purge_dups
#We followed the same 3 steps for the HiFi and the nanopore separated assemblies, the selected cutoffs are in the paper

#STEP1
minimap2 -xasm20 -t 20 H4412_onlyhif_hetlikeassembly_0.24.0.asm.hic.p_ctg.fasta m84185_240524_234358_s4.hifi_reads.fastq.gz | gzip -c - > reads_vs_assembly.paf.gz

pbcstat *.paf.gz

calcuts PB.stat > cutoffs 2>calcults.log

#STEP2
for i in $(cat M_Cutoffs6.txt) #we tried a few differet cutoffs
do

purge_dups -2 -T $i -c PB.base.cov "$FASTA".split.paf.gz > "$i".bed 2> "$i".log &

done

wait

#STEP3
FASTA="$1"
BED="$2"

get_seqs -e $BED $FASTA

