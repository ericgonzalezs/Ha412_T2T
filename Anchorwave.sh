#This is the anchorwave pipeline. It creates teh alignments and then a table 


#!/bin/bash
#SBATCH --account=def-rieseber
#SBATCH --time=3-0
#SBATCH --cpus-per-task=10
#SBATCH --mem=90G
module load StdEnv/2020 minimap2/2.24 gcc/11.3.0

export PATH=$PATH:/home/egonza02/scratch/SOFTWARE/ANCHORWAVE/anchorwave

anchorwave gff2seq -r ANN1372_HAP1_hap1.reviewed.chr_assembled.fasta -i ANN1372H1_mincov90_minID90.PANNEW76k.gmap.gff3 -o refH1.cds.fa

anchorwave gff2seq -r ANN1372_HAP2_hap2.reviewed.chr_assembled.fasta -i ANN1372H2_mincov90_minID90.PANNEW76k.gmap.gff3 -o refH2.cds.fa


minimap2 -x splice -t 10 -k 12 -a -p 0.4 -N 20 ANN1372_HAP1_hap1.reviewed.chr_assembled.fasta refH1.cds.fa > refH1.sam

minimap2 -x splice -t 10 -k 12 -a -p 0.4 -N 20 ANN1372_HAP2_hap2.reviewed.chr_assembled.fasta refH2.cds.fa > refH2.sam

##################################
#Alignment

#!/bin/bash
#SBATCH --account=def-rieseber
#SBATCH --time=2-0
#SBATCH --cpus-per-task=10
#SBATCH --mem=497G
module load StdEnv/2020 minimap2/2.24 gcc/11.3.0
export PATH=$PATH:/home/egonza02/scratch/SOFTWARE/ANCHORWAVE/anchorwave
export TMPDIR=/home/egonza02/scratch/ALIGNMENTS/GMAP/ALIGNMENTS

i=$(cat SEPHAP_GENOMES.txt | grep -v "ANN1372_V3_corrected_hap1.reviewed.chr_assembled.fasta" | head -n 1 | tail -n 1)
name=$(echo $i | cut -d "." -f 1-3)

minimap2 -x splice -t 10 -k 12 -a -p 0.4 -N 20 $i refH1.cds.fa >  "$name"".sam"


anchorwave proali -i ANN1372H1_V3_corrected_mincov90_minID90.PANNEW76k.gmap.gff3 -r ANN1372_V3_corrected_hap1.reviewed.chr_assembled.fasta -a "$name"".sam" -as refH1.cds.fa -ar refH1.sam -s $i -n "$name""_vs_ANN1372_HAP1.anchors" -o "$name""_vs_ANN1372_HAP1_anchorwave.maf" -t 9 -R 1 -Q 1 -f "$name""_vs_ANN1372_HAP1_anchorwave.f.maf"  >  "$name""_vs_ANN1372_HAP1_anchorwave.log"


############## Convert maf to bam

python2 maf-convert sam ONLY_NANO_purged_l14_m16_u400_YAHS_H1names_3DDNA_hap1_vs_Ha412_anchorwave.maf | sed 's/[0-9]\+H//g' |  samtools view -O BAM --reference ONLY_HIFI_purged_l8_m9_u400_YAHS_H1names_3DDNA_hap1.reviewed.chr_assembled_NN_chr17.fasta -  | samtools sort - > ONLY_NANO_purged_l14_m16_u400_YAHS_H1names_3DDNA_hap1_vs_Ha412_anchorwave.bam

samtools index ONLY_NANO_purged_l14_m16_u400_YAHS_H1names_3DDNA_hap1_vs_Ha412_anchorwave.bam


