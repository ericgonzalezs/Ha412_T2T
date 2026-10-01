#These are the steps we followed to fill the gaps of our assembly
#independent scripts are in the main paige for Ha412_T2T

#create a file with our Gap_pos
bash CoundNs.sh Fakefasta.fasta > GAP_POS.txt

# we concatenate our main fasta file with our HIFI assembly, the sequences we extraced from the nanopre assembly to fill the gaps and the fasta for teh telomeres sequences. 
#The file FindGaps.sh on the main page shows how we selected and extracted the nanopore sequences and the telomeric sequences

cat ONLY_HIFI_purged_l8_m9_u400_YAHS_H1names_3DDNA_hap1.reviewed.chr_assembled.fasta  ALLFASTAStoINSERTNN.fa TelomeresNN41.fa  > ONLY_H
IFI_purged_l8_m9_u400_YAHS_H1names_3DDNA_hap1.reviewed.chr_assembled_withcontigstoinsert.fasta

#we obtained teh lengths of our sequences like this
 bash Lengths.sh ONLY_HIFI_purged_l8_m9_u400_YAHS_H1names_3DDNA_hap1.reviewed.chr_assembled_withcontigstoinsert.fasta > fastalenghts.txt

#and we created our .assembly file like this
 bash Createassemblyfile.sh fastalenghts.txt GAP_POS.txt > fake.assembly

#REVISAR QUE HACE index_output
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






