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



mkdir REVIEWEDFATSATEST_TELCORRECTED
