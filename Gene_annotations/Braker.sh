#!/bin/bash
#SBATCH --account=def-rieseber
#SBATCH --time=7-0
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=48
#SBATCH --mem=200G

module load StdEnv/2023 apptainer/1.3.5

rm -r augustus_config

rm -r braker


cp -r /home/egonza02/projects/rrg-rieseber-ac/egonza02/bin/AUGUSTUS/opt/Augustus/config augustus_config

export AUGUSTUS_CONFIG_PATH=$PWD/augustus_config

apptainer exec -B ${PWD}:${PWD} /home/egonza02/projects/rrg-rieseber-ac/egonza02/bin/braker3.sif braker.pl --genome=Ha412H0V3_final.fasta.masked --prot_seq=Viridiplantae.fa \
        --threads 48 \
        --AUGUSTUS_CONFIG_PATH=/home/egonza02/scratch/ANNOTATION/Zhinqin_Xrq_SRA_Viridiplantae_Selected_shorter/augustus_config \
        --rnaseq_sets_ids=$(  for i in alignments/*bam; do base=$(basename "$i");  name="${base%.bam}";     echo "$name";   done | paste -sd,) \
        --rnaseq_sets_dirs=alignments
