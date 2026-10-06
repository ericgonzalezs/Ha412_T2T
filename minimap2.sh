minimap2 -t 20 -ax asm5 --eqx HIFI_chr.fa NANO_chr.fa > HIFI.NANO.sam

samtools view -@ 12 -bS HIFI.NANO.sam | samtools sort -@ 12 -o HIFI.NANO.sorted.bam
