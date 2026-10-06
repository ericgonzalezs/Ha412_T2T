#These are the steps we followed to fill the gaps of our assembly
#independent scripts are in the main paige for Ha412_T2T

#create a file with our Gap_pos
bash CoundNs.sh Fakefasta.fasta > GAP_POS.txt

# We concatenated our main FASTA file with the HiFi assembly, the sequences extracted from the Nanopore assembly to fill gaps, 
#and the FASTA file containing the telomeric sequences.
#We selected and extracted the Nanopore and telomeric sequences using our Pysam_semiauto.py script. 
#For each gap position, we used Pysam_semiauto.py to identify sequences in the AnchorWave or minimap2 alignments that 
#could be used to fill the gap..  

cat ONLY_HIFI_purged_l8_m9_u400_YAHS_H1names_3DDNA_hap1.reviewed.chr_assembled.fasta  ALLFASTAStoINSERTNN.fa TelomeresNN41.fa  > ONLY_H
IFI_purged_l8_m9_u400_YAHS_H1names_3DDNA_hap1.reviewed.chr_assembled_withcontigstoinsert.fasta

#we obtained teh lengths of our sequences like this
 bash Lengths.sh ONLY_HIFI_purged_l8_m9_u400_YAHS_H1names_3DDNA_hap1.reviewed.chr_assembled_withcontigstoinsert.fasta > fastalenghts.txt

#and we created our .assembly file like this
 bash Createassemblyfile.sh fastalenghts.txt GAP_POS.txt > fake.assembly

#This process performs manual, instruction-driven gap filling and scaffolding adjustments on a genome assembly 
#file in 3D-DNA / Juicebox format.
#Specifically, it uses a set of instructions (instructions_pergap.txt) to process gap/debris regions by removing unneeded fragments, 
#flipping retained ones in place, or replacing them with specified donor scaffolds in either forward or reverse orientation. Finally, 
#it updates the sequence headers to drop debris labels for flipped fragments and concatenates the revised headers with the
#reordered index map to produce a final assembly file (onlygapsfragments.with.indexes.assembly) ready for FASTA reconstruction.
#
index_output=$(bash add_indexorder2.sh fake.assembly instructions_pergap.txt)

 flipped=$(echo "$index_output" | grep -o -- '-[0-9]\+' | tr -d '-' | sort -n | uniq)

 awk -v flipped="$flipped" '
BEGIN {
    n=split(flipped,f," ")
    for(i=1;i<=n;i++) flip[f[i]]=1
}
{
    if($0 ~ /^>/) {
        id=$1; gsub(/^>/,"",id)
        idx=$2
        if(idx in flip) {
            sub(/:::debris/,"",$1)
        }
    }
    print
}' fake.assembly > fake_flipcorrected.assembly


#cat fake_flipcorrected.assembly <(bash add_indexorder.sh fake.assembly instructions_pergap.txt) > onlygapsfragments.with.indexes.assembly

cat fake_flipcorrected.assembly <(bash add_indexorder_invscaff.sh  fake.assembly instructions_pergap.txt) > onlygapsfragments.with.inde
xes.assembly

#to the .assembly file we added manually the telomeres posstions
#and then we ran

mkdir REVIEWEDFATSATEST_TELCORRECTED
Rscript ASM_TO_FASTA_ME.R onlygapsfragments.with.indexes.assembly TEST ONLY_HIFI_purged_l8_m9_u400_YAHS_H1names_3DDNA_hap1.reviewed.c
hr_assembled_withcontigstoinsert.fasta REVIEWEDFATSATEST_TELCORRECTED

#ASM_TO_FASTA_ME.R is the same script we used here https://github.com/kaede0e/stinging_nettle_genome_assembly/blob/main/1_genome_assembly_with_PBHiFi_HiC/asm_to_fasta_me.R





