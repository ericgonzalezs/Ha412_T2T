#This is the anchorwave pipeline. It creates teh alignments and then a table 

export PATH=$PATH:/DATA/home/egonzalez/SOFTWARE/ANCHORWAVE/anchor_1_2_5/AnchorWave-1.2.5


anchorwave gff2seq -r ONLY_HIFI_purged_l8_m9_u400_YAHS_H1names_3DDNA_hap1.reviewed.chr_assembled_NN_chr17.fasta -i ONLY_HIFI_purged_l8_m9_u400_YAHS_H1names_3DDNA_hap1.gff3 -o ref.cds.fa

minimap2 -x splice -t 10 -k 12 -a -p 0.4 -N 20 ONLY_HIFI_purged_l8_m9_u400_YAHS_H1names_3DDNA_hap1.reviewed.chr_assembled_NN_chr17.fasta ref.cds.fa > ref.sam

# Set the maximum number of concurrent jobs
MAX_JOBS=6

# Initialize a counter
job_count=0


for i in $(cat SEPHAP_GENOMESLast4.txt )

do

echo "Running task $i"

        name=$(echo $i | cut -d "." -f 1)

{

minimap2 -x splice -t 10 -k 12 -a -p 0.4 -N 20 $i ref.cds.fa >  "$name"".sam"

anchorwave proali -i ONLY_HIFI_purged_l8_m9_u400_YAHS_H1names_3DDNA_hap1.gff3 -r ONLY_HIFI_purged_l8_m9_u400_YAHS_H1names_3DDNA_hap1.reviewed.chr_assembled_NN_chr17.fasta -a "$name"".sam" -as ref.cds.fa -ar ref.sam -s $i -n "$name""_vs_Ha412.anchors" -o "$name""_vs_Ha412_anchorwave.maf" -t 9 -R 1 -Q 1 -f "$name""_vs_Ha412_anchorwave.f.maf"  >  "$name""_vs_Ha412_anchorwave.log"
} &

 # Increment the job counter
    job_count=$((job_count + 1))

    # If the job counter reaches MAX_JOBS, wait for all to finish
    if (( job_count == MAX_JOBS )); then
        wait  # Wait for all background jobs to finish
        job_count=0  # Reset the counter
    fi
done

# Wait for any remaining jobs
wait
echo "All tasks completed!"


############## Convert maf to bam

python2 maf-convert sam ONLY_NANO_purged_l14_m16_u400_YAHS_H1names_3DDNA_hap1_vs_Ha412_anchorwave.maf | sed 's/[0-9]\+H//g' |  samtools view -O BAM --reference ONLY_HIFI_purged_l8_m9_u400_YAHS_H1names_3DDNA_hap1.reviewed.chr_assembled_NN_chr17.fasta -  | samtools sort - > ONLY_NANO_purged_l14_m16_u400_YAHS_H1names_3DDNA_hap1_vs_Ha412_anchorwave.bam

samtools index ONLY_NANO_purged_l14_m16_u400_YAHS_H1names_3DDNA_hap1_vs_Ha412_anchorwave.bam


