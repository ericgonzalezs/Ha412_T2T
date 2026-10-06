import pysam
import sys

if len(sys.argv) != 6:
    print("Usage: python Pysam_semiauto.py <bamfile> <chromosome> <start> <end> <mode: indel|all>")
    sys.exit(1)

bamfile = sys.argv[1]
chrom = sys.argv[2]
gap_start = int(sys.argv[3])
gap_end = int(sys.argv[4])
mode = sys.argv[5].lower()

bam = pysam.AlignmentFile(bamfile, "rb")

if mode == "indel":
    # ---------- SCRIPT 1 (insertions only, keep original output) ----------
 for read in bam.fetch(chrom, gap_start-1, gap_end):
    if read.is_unmapped or read.reference_name != chrom or read.mapping_quality <= 20:
        continue

    ref_pos = read.reference_start
    q_pos   = 0
    seq     = read.query_sequence

    for op, length in read.cigartuples or []:
        if op in (0, 7, 8):  # M, =, X
            ref_pos += length
            q_pos   += length

        elif op == 1:  # Insertion relative to reference
            # insertion occurs at current ref_pos
            if gap_start-1 <= ref_pos < gap_end:
                ins_seq = seq[q_pos:q_pos + length]
                print(f">{read.query_name}|{chrom}:{ref_pos}")
                print(ins_seq)
            q_pos += length

        elif op in (2, 3):  # deletion / ref skip
            ref_pos += length

        elif op == 4:  # soft clip
            q_pos += length



elif mode == "all":
    # ---------- SCRIPT 2 (all aligned sequences, keep original output) ----------
 for read in bam.fetch(chrom, gap_start-1, gap_end):
    if read.is_unmapped or read.reference_name != chrom or read.mapping_quality <= 20:
        continue

    ref_pos = read.reference_start
    q_pos   = 0
    seq     = read.query_sequence
    seq_parts = []

    for op, length in read.cigartuples or []:
        if op in (0, 7, 8):  # M, =, X → matches/mismatches
            for i in range(length):
                if gap_start-1 <= ref_pos < gap_end:
                    seq_parts.append(seq[q_pos])
                ref_pos += 1
                q_pos += 1

        elif op == 1:  # Insertion
            # insertion occurs **between reference bases**
            if gap_start-1 <= ref_pos < gap_end:
                seq_parts.append(seq[q_pos:q_pos+length])
            q_pos += length

        elif op in (2, 3):  # deletion / ref skip
            ref_pos += length

        elif op == 4:  # soft clip
            q_pos += length

    if seq_parts:
        print(f">{read.query_name}|{chrom}:{gap_start}-{gap_end}")
        print("".join(seq_parts))


else:
    print("Error: mode must be 'indel' or 'all'")
    sys.exit(1)

bam.close()
