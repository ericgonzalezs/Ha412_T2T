#This Juicer pipeline takes de Hi-C and aling it to the contigs to produce the merged_nodups.txt table that we used for the scaffolding with Yahs


bash scripts/juicer.sh -D $PWD -g Ha412_ONLY_HIFI_purged.asm.hic.p -s DpnII -p restriction_sites/Ha412_DpnII.chrom.sizes -y restriction_sites/Ha412_DpnII.txt -z references/purged.fa -t 20  -S early

