##############################
# HA412V3 centromere annotations
# June 2026
# Cassandra Elphinstone
################################

# Run final HA412v3 genome from Eric

# move to rorqual
cd /scratch/celphin/repeats/sunflower2
scp celphin@asteroid.zoology.ubc.ca:/AsteroidScratch/FORCASSANDRA/Ha412H0V3_final.fasta .
mv Ha412H0V3_final.fasta Ha412H0V3final.fasta

# run RepeatOBserver
cat << EOF > Auto_Ha412H0V3final.sh
#!/bin/bash
#SBATCH --account=def-henryg
#SBATCH --time=17:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=19
#SBATCH --mem=191000M

module load StdEnv/2020
module load seqkit/2.3.1
module load emboss/6.6.0
module load r/4.2.2

srun Setup_Run_Repeats.sh -i Ha412H0V3final -f Ha412H0V3final.fasta -h H0 -c 19 -m 191000M -g FALSE

EOF

sbatch Auto_Ha412H0V3final.sh


################################
# Compare results with known centromeric repeats

# copy to genome another directory to blast known centromeric repeats found using ChIPseq
# from https://www.frontiersin.org/journals/plant-science/articles/10.3389/fpls.2015.00912/full

cd /scratch/celphin/repeats/sunflower2
cp Ha412H0V3final.fasta /scratch/celphin/repeats/sunflower2/run_genomes

# check name order
grep ">" Ha412H0V3final.fasta |head -n 20

#--------------
# Run BLAST

tmux new-session -s sunflower
tmux attach-session -t sunflower

salloc -c1 --time 3:00:00 --mem 120000m --account def-henryg

#module spider blast+/2.11.0
module load StdEnv/2020  
module load gcc/9.3.0
module load blast+/2.11.0

cd /scratch/celphin/repeats/sunflower2/run_genomes/

for fasta_file in Ha412H0V3final.fasta; do
    # Remove the .fasta extension 
    genome="${fasta_file%.fasta}"

    # convert genomes to easily searchable blastdb
    makeblastdb -in /scratch/celphin/repeats/sunflower2/run_genomes/${genome}.fasta \
    -out /scratch/celphin/repeats/sunflower2/run_genomes/DB_${genome}/ -dbtype nucl -title DB_${genome}

    mkdir DB_${genome}
    mv DB_${genome}.* DB_${genome}/

    #-------
    # run blast
    module load StdEnv/2020
    module load blast/2.2.26

    blastn -query /scratch/celphin/repeats/sunflower2/run_genomes/centromere_repeats/LC075744.fasta \
    -db /scratch/celphin/repeats/sunflower2/run_genomes/DB_${genome}/DB_${genome} \
    -evalue 1e-5 -outfmt 6 -out /scratch/celphin/repeats/sunflower2/run_genomes/blast_out/LC075744_${genome}.out

    blastn -query /scratch/celphin/repeats/sunflower2/run_genomes/centromere_repeats/LC075745.fasta \
    -db /scratch/celphin/repeats/sunflower2/run_genomes/DB_${genome}/DB_${genome} \
    -evalue 1e-5 -outfmt 6 -out /scratch/celphin/repeats/sunflower2/run_genomes/blast_out/LC075745_${genome}.out

    #---------------
    # want output as bed file -> convert blast.out to bed files
    cat /scratch/celphin/repeats/sunflower2/run_genomes/blast_out/LC075744_${genome}.out | awk '$0 ~ "|" {printf substr($2,1,20) " " substr($9,1,20) " " substr($10,1,20) "\n"; }'> /scratch/celphin/repeats/sunflower2/run_genomes/blast_bed/LC075744_${genome}.bed
    cat /scratch/celphin/repeats/sunflower2/run_genomes/blast_out/LC075745_${genome}.out | awk '$0 ~ "|" {printf substr($2,1,20) " " substr($9,1,20) " " substr($10,1,20) "\n"; }'> /scratch/celphin/repeats/sunflower2/run_genomes/blast_bed/LC075745_${genome}.bed

done

