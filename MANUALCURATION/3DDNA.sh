#This is how we prepared the .assembly and .hic files for visualization and manual corrections in Juicebox.
#We followed the same steps for the HiFi and Nanopore assemblies separately

run-asm-pipeline.sh -r 0 ONLY_HIFI_purged_l8_m9_u400_YAHS.fasta merged_nodups.txt
