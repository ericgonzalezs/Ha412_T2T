#hifiasm script for the HiFi assembly
hifiasm-0.24.0/hifiasm  -o H4412_onlyhif_hetlikeassembly_0.24.0.asm  -t 50 --h1 Ha412_hic_R1.fastq.gz --h2 Ha412_hic_R2.fastq.gz m84185_240524_234358_s4.hifi_reads.fastq.gz

#hifiasm script for the nanopore assembly
hifiasm-0.24.0/hifiasm --ont -o H4412_nano_hetlikeassembly_0.24.0.asm  -t 32 --h1 Ha412_hic_R1.fastq.gz --h2 Ha412_hic_R2.fastq.gz ALL_NANO.fastq.gz

#hifiasm script for the hybrid (HiFi + Nanopore) assembly
hifiasm-0.24.0/hifiasm  -o H4412_nano_hetlikeassembly_0.24.0.asm  -t 50  --ul ALL_NANO.fastq.gz --h1 Ha412_hic_R1.fastq.gz --h2 Ha412_hic_R2.fastq.gz m84185_240524_234358_s4.hifi_reads.fastq.gz
