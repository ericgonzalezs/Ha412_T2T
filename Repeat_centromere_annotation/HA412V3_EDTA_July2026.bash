##############################
# HA412V3 EDTA run 
# July 2026
# Cassandra Elphinstone
################################
# On rorqual
cd /scratch/celphin/EDTA
# Copy genome here: /scratch/celphin/EDTA/Ha412H0V3final.fasta 

# Split genome into separate fasta files
OUTDIR="chrom_fastas"
mkdir -p "${OUTDIR}"

# splits fasta and makes chrom_fastas/<id>.fa where <id> is the fasta header up to first whitespace
awk -v outdir="${OUTDIR}" '
  BEGIN{FS="[ \t]"}
  /^>/{
    header=$0
    id=substr($1,2)   # remove leading ">"
    out=outdir"/"id".fa"
    print $0 > out
    next
  }
  {
    print $0 >> out
  }
' Ha412H0V3final.fasta 


################################
# Setup EDTA container
tmux new-session -s sunflower
tmux attach-session -t sunflower

# on login node
cd /scratch/celphin/EDTA
module load StdEnv/2023 apptainer/1.3.5
apptainer pull EDTA.sif docker://quay.io/biocontainers/edta:2.3.0--hdfd78af_0

# WARNING: 'nodev' mount option set on /var/tmp, it could be a source of failure during build process
# Done

# Check dependencies included
apptainer exec /scratch/celphin/EDTA/EDTA.sif RepeatMasker -e ncbi -h | head
apptainer exec /scratch/celphin/EDTA/EDTA.sif which RMblast

#------------------
# Check cd-hit-est

module load StdEnv/2023 apptainer/1.3.5
EDTA_SIF="/scratch/celphin/EDTA/EDTA.sif"

apptainer exec --cleanenv "$EDTA_SIF" bash -lc 'which cd-hit-est || echo "cd-hit-est not found"; cd-hit-est -h | head'

# Works

#############################
# Test with salloc

tmux new-session -s sunflower
tmux attach-session -t sunflower

salloc -c32 --time 23:50:00 --mem 128000m --account def-henryg

cd /scratch/celphin/EDTA/

module load StdEnv/2023 apptainer/1.3.5

EDTA_SIF="/scratch/celphin/EDTA/EDTA.sif"

WORK="/scratch/celphin/EDTA/edta_from_sif"
rm -rf "$WORK"
mkdir -p "$WORK"

# Extract EDTA from the SIF (optional; safe to keep)
apptainer exec "$EDTA_SIF" bash -lc '
  set -e
  mkdir -p /tmp/edta_extract/EDTA
  cp -f /usr/local/bin/EDTA.pl /tmp/edta_extract/EDTA.pl
  cp -r /usr/local/share/EDTA /tmp/edta_extract/EDTA/
'

OUTDIR="/scratch/celphin/EDTA/edta_out_genome"
mkdir -p "$OUTDIR"
cd "$OUTDIR"

apptainer exec --cleanenv "$EDTA_SIF" bash -lc '
  set -e
  /usr/local/bin/EDTA.pl --genome "/scratch/celphin/EDTA/Ha412H0V3final.fasta" --species others --step all --anno 1 --sensitive 1 --evaluate 0 --threads 32
'

#########################################################
##### Extensive de-novo TE Annotator (EDTA) v2.3  #####
##### Shujun Ou (shujun.ou.1@gmail.com)             #####
#########################################################


# Parameters: --genome /scratch/celphin/EDTA/Ha412H0V3final.fasta --species others --step all --anno 1 --sensitive 1 --evaluate 0 --threads 32


# Wed Aug 12 19:48:34 UTC 2026    Dependency checking:
        # All passed!

# Wed Aug 12 19:48:44 UTC 2026    Cleaning and normalizing sequence IDs...
# Encoded 426 sequences with 8-char codes (prefix '_J' + 6 base-62 digits, longest clean ID: 20, id_len_max: 8, longest scaffold: 209803016 bp)
        # Sequence IDs encoded. Mapping file: Ha412H0V3final.fasta.mod.seqid.map

# Wed Aug 12 19:50:09 UTC 2026    Obtain raw TE libraries using various structure-based programs:
# Wed Aug 12 19:50:09 UTC 2026    EDTA_raw: Check dependencies, prepare working directories.

# Wed Aug 12 19:52:43 UTC 2026    Start to find LTR candidates.

# Wed Aug 12 19:52:43 UTC 2026    Identify LTR retrotransposon candidates from scratch.


##################################
# Run EDTA on each chromosome in a loop to speed up run time
# Note: produces many more tmp files and can swamp quotas

cat > EDTA_HA412_chr.sh << 'EOF'
#!/usr/bin/env bash
#SBATCH --account=def-henryg
#SBATCH --job-name=edta_array
#SBATCH --cpus-per-task=32
#SBATCH --mem=128G
#SBATCH --time=48:00:00
#SBATCH --output=edta_array.%A_%a.out
#SBATCH --error=edta_array.%A_%a.err

set -euo pipefail

cd /scratch/celphin/EDTA/

module load StdEnv/2023 apptainer/1.3.5

CHRS_DIR="/scratch/celphin/EDTA/chrom_fastas"
THREADS=32

LIST_FILE="chrom_list.txt"
EDTA_SIF="/scratch/celphin/EDTA/EDTA.sif"

if [[ ! -f "${LIST_FILE}" ]]; then
  ls "${CHRS_DIR}"/*.fa | sort > "${LIST_FILE}"
fi

N=$(wc -l < "${LIST_FILE}")
TASK_ID="${SLURM_ARRAY_TASK_ID}"

if (( TASK_ID < 0 || TASK_ID >= N )); then
  echo "Bad TASK_ID=${TASK_ID}; N=${N}"
  exit 1
fi

fasta="$(sed -n "$((TASK_ID+1))p" "${LIST_FILE}")"
echo "Running EDTA on: ${fasta}"

chr="$(basename "${fasta}" .fa)"

OUTBASE="/scratch/celphin/EDTA/edta_out"
OUTDIR="${OUTBASE}/${chr}"
mkdir -p "${OUTDIR}"
cd "${OUTDIR}"

GENOME_DIR="$(dirname "${fasta}")"

apptainer exec --cleanenv \
  "${EDTA_SIF}" bash -lc '
    set -e
    /usr/local/bin/EDTA.pl --genome "'"$fasta"'" --species others --step all --anno 1 --sensitive 1 --evaluate 0 --force 1 --threads 32
  '
EOF

ls /scratch/celphin/EDTA/chrom_fastas/*.fa | sort > chrom_list.txt


MAX_JOBS=2
N=$(wc -l < chrom_list.txt)
sbatch --array=0-$((N-1))%${MAX_JOBS} EDTA_HA412_chr.sh

sq
#54564840_[0-16%  celphin def-henryg_c     edta_array  PD 2-00:00:00     1   32        N/A     64G  (Priority)

# running on Fir with just two chromosomes at a time to prevent too many files

# Start
quota
                            # Description                Space         # of files
                   # /home (user celphin)        44GiB/  48GiB         493K/ 500K
                # /scratch (user celphin)        14TiB/  19TiB         542K/1000K


#------------------------
# tar raw files as chromosomes finish
cd edta_out

tar -czf Ha412HOv3Chr01.fa.mod.EDTA.raw.tar.gz --remove-files /scratch/celphin/EDTA/edta_out/Ha412HOv3Chr01/Ha412HOv3Chr01.fa.mod.EDTA.raw
tar -czf Ha412HOv3Chr02.fa.mod.EDTA.raw.tar.gz --remove-files /scratch/celphin/EDTA/edta_out/Ha412HOv3Chr02/Ha412HOv3Chr02.fa.mod.EDTA.raw

tar -czf Ha412HOv3Chr03.fa.mod.EDTA.raw.tar.gz --remove-files /scratch/celphin/EDTA/edta_out/Ha412HOv3Chr03/Ha412HOv3Chr03.fa.mod.EDTA.raw
tar -czf Ha412HOv3Chr04.fa.mod.EDTA.raw.tar.gz --remove-files /scratch/celphin/EDTA/edta_out/Ha412HOv3Chr04/Ha412HOv3Chr04.fa.mod.EDTA.raw

tar -czf Ha412HOv3Chr05.fa.mod.EDTA.raw.tar.gz --remove-files /scratch/celphin/EDTA/edta_out/Ha412HOv3Chr05/Ha412HOv3Chr05.fa.mod.EDTA.raw
tar -czf Ha412HOv3Chr06.fa.mod.EDTA.raw.tar.gz --remove-files /scratch/celphin/EDTA/edta_out/Ha412HOv3Chr06/Ha412HOv3Chr06.fa.mod.EDTA.raw

tar -czf Ha412HOv3Chr07.fa.mod.EDTA.raw.tar.gz --remove-files /scratch/celphin/EDTA/edta_out/Ha412HOv3Chr07/Ha412HOv3Chr07.fa.mod.EDTA.raw
tar -czf Ha412HOv3Chr08.fa.mod.EDTA.raw.tar.gz --remove-files /scratch/celphin/EDTA/edta_out/Ha412HOv3Chr08/Ha412HOv3Chr08.fa.mod.EDTA.raw

tar -czf Ha412HOv3Chr09.fa.mod.EDTA.raw.tar.gz --remove-files /scratch/celphin/EDTA/edta_out/Ha412HOv3Chr09/Ha412HOv3Chr09.fa.mod.EDTA.raw
tar -czf Ha412HOv3Chr10.fa.mod.EDTA.raw.tar.gz --remove-files /scratch/celphin/EDTA/edta_out/Ha412HOv3Chr10/Ha412HOv3Chr10.fa.mod.EDTA.raw

tar -czf Ha412HOv3Chr11.fa.mod.EDTA.raw.tar.gz --remove-files /scratch/celphin/EDTA/edta_out/Ha412HOv3Chr11/Ha412HOv3Chr11.fa.mod.EDTA.raw
tar -czf Ha412HOv3Chr12.fa.mod.EDTA.raw.tar.gz --remove-files /scratch/celphin/EDTA/edta_out/Ha412HOv3Chr12/Ha412HOv3Chr12.fa.mod.EDTA.raw

tar -czf Ha412HOv3Chr13.fa.mod.EDTA.raw.tar.gz --remove-files /scratch/celphin/EDTA/edta_out/Ha412HOv3Chr13/Ha412HOv3Chr13.fa.mod.EDTA.raw
tar -czf Ha412HOv3Chr14.fa.mod.EDTA.raw.tar.gz --remove-files /scratch/celphin/EDTA/edta_out/Ha412HOv3Chr14/Ha412HOv3Chr14.fa.mod.EDTA.raw

tar -czf Ha412HOv3Chr15.fa.mod.EDTA.raw.tar.gz --remove-files /scratch/celphin/EDTA/edta_out/Ha412HOv3Chr15/Ha412HOv3Chr15.fa.mod.EDTA.raw
tar -czf Ha412HOv3Chr16.fa.mod.EDTA.raw.tar.gz --remove-files /scratch/celphin/EDTA/edta_out/Ha412HOv3Chr16/Ha412HOv3Chr16.fa.mod.EDTA.raw

tar -czf Ha412HOv3Chr17.fa.mod.EDTA.raw.tar.gz --remove-files /scratch/celphin/EDTA/edta_out/Ha412HOv3Chr17/Ha412HOv3Chr17.fa.mod.EDTA.raw


####################################
# EDTA summary per chromosome

nano extract_repeat_classes.sh

#!/usr/bin/env bash
set -euo pipefail

indir="/scratch/celphin/EDTA/edta_out"
pattern="*.fa.mod.EDTA.TEanno.sum"

outdir="${indir}/repeat_class_matrices"
mkdir -p "$outdir"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

long_pct="${tmpdir}/long_pct.tsv"   # chrom class pct
long_bp="${tmpdir}/long_bp.tsv"     # chrom class bp

: > "$long_pct"
: > "$long_bp"

# Build long tables
while IFS= read -r f; do
  bn="$(basename "$f")"
  chrom="${bn%.fa.mod.EDTA.TEanno.sum}"

  # pct
  awk -v chrom="$chrom" '
    BEGIN{inblk=0}
    /^Repeat Classes/ {inblk=1; next}
    inblk && /^snRNA/ {inblk=0}
    inblk {
      line=$0
      sub(/^[ \t]+/, "", line)

      # Split on whitespace without regex character classes
      n=split(line,a,"[[:space:]]+")
      # If awk treats this weirdly, fall back to split with no 3rd arg:
      if (n < 4) {
        n=split(line,a)
      }

      # Expect: class count bpMasked pct%
      if (n>=4 && a[1] ~ /^[A-Za-z0-9_]+$/ && a[2] ~ /^[0-9]+$/ && a[3] ~ /^[0-9]+$/ && a[4] ~ /%$/) {
        pct=a[4]; sub(/%$/, "", pct)
        print chrom "\t" a[1] "\t" pct
      }
    }
  ' "$f" >> "$long_pct"

  # bp
  awk -v chrom="$chrom" '
    BEGIN{inblk=0}
    /^Repeat Classes/ {inblk=1; next}
    inblk && /^snRNA/ {inblk=0}
    inblk {
      line=$0
      sub(/^[ \t]+/, "", line)

      n=split(line,a,"[[:space:]]+")
      if (n < 4) {
        n=split(line,a)
      }

      if (n>=4 && a[1] ~ /^[A-Za-z0-9_]+$/ && a[2] ~ /^[0-9]+$/ && a[3] ~ /^[0-9]+$/ && a[4] ~ /%$/) {
        print chrom "\t" a[1] "\t" a[3]
      }
    }
  ' "$f" >> "$long_bp"

done < <(find "$indir" -name "$pattern" | sort)

# Gather axes
chroms_file="${tmpdir}/chroms.txt"
classes_file="${tmpdir}/classes.txt"

cut -f1 "$long_pct" | sort -u > "$chroms_file"
cut -f2 "$long_pct" | sort -u > "$classes_file"

fill_value="NA"
pct_out="${outdir}/repeat_class_pct_matrix.tsv"
bp_out="${outdir}/repeat_class_bp_matrix.tsv"

make_matrix () {
  local long="$1"
  local out="$2"

  awk -v OFS='\t' -v fill="$fill_value" \
      -v chroms="$chroms_file" -v classes="$classes_file" -v long="$long" '
    BEGIN{
      # load chromosome columns
      while((getline c < chroms) > 0){ g[++nc]=c }

      # load class rows
      while((getline k < classes) > 0){ r[++nr]=k }

      # init
      for (i=1; i<=nr; i++){
        for (j=1; j<=nc; j++){
          val[i,j]=fill
        }
      }

      # fill values
      while((getline line < long) > 0){
        split(line,a,FS)
        c=a[1]; k=a[2]; v=a[3]

        # find indices (keeps awk compatible, avoids SUBSEP tricks)
        # (Could be sped up, but fine for typical EDTA class counts)
        for (j=1; j<=nc; j++) if (g[j]==c) break
        for (i=1; i<=nr; i++) if (r[i]==k) break
        if (i<=nr && j<=nc) val[i,j]=v
      }

      # header
      printf "class"
      for (j=1; j<=nc; j++) printf OFS g[j]
      printf "\n"

      # rows
      for (i=1; i<=nr; i++){
        printf r[i]
        for (j=1; j<=nc; j++) printf OFS val[i,j]
        printf "\n"
      }
    }
  ' > "$out"
}

make_matrix "$long_pct" "$pct_out"
make_matrix "$long_bp"  "$bp_out"

echo "Wrote:"
echo "  $pct_out"
echo "  $bp_out"

bash extract_repeat_classes.sh

# remove the extra classes
pct_out="/scratch/celphin/EDTA/edta_out/repeat_class_matrices/repeat_class_pct_matrix.tsv"
bp_out="/scratch/celphin/EDTA/edta_out/repeat_class_matrices/repeat_class_bp_matrix.tsv"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

for f in "$pct_out" "$bp_out"; do
  out="${tmpdir}/$(basename "$f")"
  awk -F'\t' '
    NR==1 {print; next}
    $1 !~ /^TE_/ && $1 !~ /^Ha412/
  ' "$f" > "$out"
  mv "$out" "$f"
done

more repeat_class_matrices/repeat_class_pct_matrix.tsv
# class   Ha412HOv3Chr01  Ha412HOv3Chr02  Ha412HOv3Chr03  Ha412HOv3Chr04  Ha412HOv3Chr05  Ha412HOv3Chr06  Ha412HOv3Chr07  Ha412HOv3Chr08
# LINE-CRE     0.13    0.10    0.11    0.11    0.09    0.08    0.08    0.13
# LINE-L1      0.62    0.57    0.54    0.31    0.58    0.39    0.61    0.54
# LINE-RTE     0.10    0.05    0.08    0.04    0.09    0.07    0.05    0.04

# LTR-Bel_Pao 0.00    NA      NA      NA      NA      NA      NA      NA
# LTR-Copia   7.73    7.60    6.69    8.78    6.02    7.28    7.66    7.47
# LTR-Gypsy   21.19   25.27   23.83   30.50   27.44   23.46   25.40   21.01
# LTR-unknown 41.33   43.24   40.30   36.66   41.76   43.64   43.34   46.19

# TIR-CACTA   0.03    0.03    0.02    0.02    0.06    0.01    0.03    0.02
# TIR-Mutator 0.29    0.32    0.26    0.12    0.15    0.20    0.26    0.10
# TIR-PIF_Harbinger   0.27    0.30    0.25    0.18    0.15    0.31    0.16    0.31
# TIR-PILE    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00
# TIR-POLE    0.08    0.08    0.08    0.08    0.07    0.08    0.06    0.08
# TIR-Tc1_Mariner     0.01    0.00    NA      0.00    NA      0.00    0.01    0.01
# TIR-hAT     0.08    0.04    0.04    0.03    0.08    0.03    0.06    0.04

# helitron        0.14    0.13    0.26    0.13    0.16    0.17    0.10    0.27
# pararetrovirus  NA      NA      NA      NA      NA      NA      NA      0.02
# repeat_fragment 4.28    2.74    3.82    2.94    2.87    3.50    2.56    2.13
# tRNA    0.01    NA      NA      NA      NA      NA      NA      NA


# Previous analyses of sunflower repeats had LTRs making up almost all of the repeats: 
# "More than three quarters of the sunflower genome consisted of long terminal repeat retrotransposons (LTR-RTs), of which 59% belong to the Gypsy evolutionary lineage". Badouin et al 2017; 
# "In general, 74 to 83% of the genomes are composed of transposable elements (TEs), with 70 to 73% of these being long terminal repeat–retrotransposons (LTR-RTs)” Huang et al 2023. 
# What is the difference?


####################################
# TE sorter
# https://github.com/zhangrengang/TEsorter
# https://academic.oup.com/hr/article/doi/10.1093/hr/uhac017/6532211?login=true

# Fir login3
tmux new-session -s TEsorter
tmux attach-session -t TEsorter


module load StdEnv/2023
module load python/3.13.2 
pip install biopython
pip install xopen
module load blast+
module load  hmmer/3.4

git clone https://github.com/zhangrengang/TEsorter
cd TEsorter

# create a writable prefix for Python packages
mkdir -p /scratch/celphin/TEsorter_py

# install into that prefix
python3 -m pip install --upgrade pip
python3 -m pip install . --prefix=/scratch/celphin/TEsorter_py

# Export path
export PATH=/scratch/celphin/TEsorter_py/bin:$PATH
export PYTHONPATH=/scratch/celphin/TEsorter_py/lib/python*/site-packages:$PYTHONPATH


#----------------
# To run
# TEs from EDTA?
cd /scratch/celphin/EDTA/TEsorter
PYTHONPATH=$PWD python3 -m TEsorter --help

PYTHONPATH=$PWD python3 -m TEsorter \
  /scratch/celphin/EDTA/edta_out/Ha412HOv3Chr01/Ha412HOv3Chr01.fa.mod.EDTA.TElib.fa \
  -db rexdb-plant

# Running - fast 5min per chr

# Order           Superfamily      # of Sequences# of Clade Sequences    # of Clades# of full Domains
# LTR             Copia                       393            330             11            100
# LTR             Gypsy                       454            389              7             72
# LTR             mixture                       2              0              0              0
# LINE            unknown                       3              0              0              0
# TIR             EnSpm_CACTA                  19              0              0              0
# TIR             MuDR_Mutator                 79              0              0              0
# TIR             PIF_Harbinger                31              0              0              0
# TIR             Tc1_Mariner                  17              0              0              0
# TIR             hAT                          24              0              0              0
# Helitron        unknown                      17              0              0              0


#------------------------------
# run on all chromosomes

CHR_LIST=(02 03 04 05 06 07 08 09 10 11)
CHR_LIST=(12 13 14 15 16 17)
for c in "${CHR_LIST[@]}"; do
  GENOME="Ha412HOv3Chr${c}"
  infa="/scratch/celphin/EDTA/edta_out/${GENOME}/${GENOME}.fa.mod.EDTA.TElib.fa"

  PYTHONPATH=$PWD python3 -m TEsorter \
    "$infa" \
    -db rexdb-plant 

done


#######################################
# explore data 
mkdir data
mv Ha* data/
cd /scratch/celphin/EDTA/TEsorter/data

grep 'LTR/unknown' /scratch/celphin/EDTA/TEsorter/data/Ha412HOv3Chr01.fa.mod.EDTA.TElib.fa.rexdb-plant.cls.tsv
#TE     Order   Superfamily     Clade   Complete        Strand  Domains
# TE_00001252_INT#LTR/unknown     LTR     Copia   SIRE    no      -       GAG|SIRE
# TE_00001257_INT#LTR/unknown     LTR     Gypsy   Tekay   no      -       GAG|Tekay PROT|Tekay CHD|Tekay
# TE_00001263_INT#LTR/unknown     LTR     Gypsy   Athila  yes     -       GAG|Athila PROT|Athila RT|Athila RH|Athila INT|Athila
# TE_00001264_INT#LTR/unknown     LTR     Gypsy   Athila  yes     -       GAG|Athila PROT|Athila RT|Athila RH|Athila INT|Athila
# TE_00001272_INT#LTR/unknown     LTR     Gypsy   Athila  no      -       PROT|Athila
# TE_00001280_INT#LTR/unknown     LTR     Copia   SIRE    no      -       GAG|SIRE
# TE_00001303_INT#LTR/unknown     LTR     Copia   SIRE    no      -       GAG|SIRE
# TE_00001306_INT#LTR/unknown     LTR     Gypsy   Reina   yes     -       GAG|Reina PROT|Reina RT|Reina RH|Reina INT|Reina CHD|Reina
# TE_00001308_INT#LTR/unknown     LTR     Gypsy   Tekay   no      -       PROT|Tekay RH|Tekay INT|Tekay CHD|Tekay
# TE_00001310_INT#LTR/unknown     LTR     Gypsy   Athila  no      -       GAG|Athila PROT|Athila
# TE_00001311_INT#LTR/unknown     LTR     Copia   Ivana   no      -       GAG|Ivana


 more /scratch/celphin/EDTA/edta_out/Ha412HOv3Chr01/Ha412HOv3Chr01.fa.mod.EDTA.TEanno.gff3
# ##gff-version 3
# ##date Fri Aug 14 01:17:40 PDT 2026
# ##This file contains repeats annotated by EDTA v2.3 with both structural and homology methods. Repeats can be overlapping due to nested insertions.
# ##This file follows the ENSEMBL standard: https://useast.ensembl.org/info/website/upload/gff3.html
# ##Column 3: Sequence Ontology of repeat features. Please refer to the SO database for more details: http://www.sequenceontology.org/. In cases where th
# e SO database does not have the repeat feature, tentative SO names are used, with a full list included in EDTA/bin/TE_Sequence_Ontology.txt (Enhancemen
# t notes), and the sequence_ontology in Column 9 uses the closest parent SO.
# ##Column 7: The Smith-Waterman score generated by RepeatMasker, only available for homology entries.
# ##Column 9:
# ##      ID: unique ID for this feature in the genome.
# ##      classification: Same as Column 3 but formatted following the RepeatMasker naming convention.
# ##      sequence_ontology: Sequence Ontology ID of the feature.
# ##      identity: Sequence identity (0-1) between the library sequence and the target region.
# ##      ltr_identity: Sequence identity (0-1) between the left and right LTR regions for structurally annotated LTR elements.
# ##      Name: Repeat family name. Some may be shown as coordinates, which are single-copy and structrually identified elements that are not included in
 # the repeat library.
# ##      method: Indicate if this entry is produced by structural annotation or homology annotation.
# ##      motif/TSD/TIR: structural features of structurally annotated LTR and TIR elements.
# ##For more details about this file, please refer to the EDTA wiki: https://github.com/oushujun/EDTA/wiki/Making-sense-of-EDTA-usage-and-outputs---Q&A
# ##seqid source sequence_ontology start end score strand phase attributes
# Ha412HOv3Chr01  EDTA    Copia_LTR_retrotransposon       1       859     489     -       .       ID=TE_homo_0;Name=TE_00002742_INT;classification=LTR/Co
# pia;sequence_ontology=SO:0002264;identity=0.858;method=homology
# ###
# Ha412HOv3Chr01  EDTA    Copia_LTR_retrotransposon       1060    1462    520     -       .       ID=TE_homo_1;Name=TE_00002742_INT;classification=LTR/Co
# pia;sequence_ontology=SO:0002264;identity=0.768;method=homology
# ###
# Ha412HOv3Chr01  EDTA    Copia_LTR_retrotransposon       1702    3023    578     -       .       ID=TE_homo_2;Name=TE_00002742_INT;classification=LTR/Co
# pia;sequence_ontology=SO:0002264;identity=0.844;method=homology
# ###
# Ha412HOv3Chr01  EDTA    Copia_LTR_retrotransposon       7840    8295    451     -       .       ID=TE_homo_3;Name=TE_00002742_INT;classification=LTR/Co
# pia;sequence_ontology=SO:0002264;identity=0.847;method=homology
# ###
# Ha412HOv3Chr01  EDTA    Copia_LTR_retrotransposon       10401   10594   442     -       .       ID=TE_homo_4;Name=TE_00002742_INT;classification=LTR/Co
# pia;sequence_ontology=SO:0002264;identity=0.901;method=homology

#--------------------------------
# join the class info to the gff3 positions for each TE
# Chromosomes are all labelled 1 currently = Ha412HOv3Chr01

nano join_edta_gff3_with_cls.py

#!/usr/bin/env python3
import sys

cls_path = sys.argv[1]
gff_path = sys.argv[2]

# Build lookup from cls.tsv
# Assumption (matches your example):
#   col1: TE_00001252_INT#LTR/unknown
#   col2-5: Order, Superfamily, Clade, Complete
# Join key we’ll use: strip after '#' so it becomes TE_00001252_INT
cls = {}
with open(cls_path, "r", encoding="utf-8") as f:
    for line in f:
        line = line.rstrip("\n")
        if not line or line.startswith("#"):
            continue
        parts = line.split("\t")
        if len(parts) < 5:
            continue
        te_full = parts[0]
        te_key = te_full.split("#", 1)[0]  # before '#'
        cls[te_key] = {
            "Order": parts[1],
            "Superfamily": parts[2],
            "Clade": parts[3],
            "Complete": parts[4],
        }

# Stream gff3 and join
out_lines = []
out_lines.append("Name\tChr\tStart\tEnd\tRepeatclass\tOrder\tSuperfamily\tClade\tComplete")

with open(gff_path, "r", encoding="utf-8") as f:
    for line in f:
        if not line or line.startswith("#"):
            continue
        parts = line.rstrip("\n").split("\t")
        if len(parts) < 9:
            continue

        seqid = parts[0]
        repeatclass = parts[2]
        start = parts[3]
        end = parts[4]
        attr = parts[8]

        # Parse attributes key=value;... in column 9
        attrs = {}
        for kv in attr.split(";"):
            kv = kv.strip()
            if not kv:
                continue
            if "=" in kv:
                k, v = kv.split("=", 1)
                attrs[k] = v

        edta_name = attrs.get("Name", ".")   # e.g. TE_00002742_INT
        # edta_id may be TE_homo_0 etc; usually not present in cls.tsv
        # edta_id = attrs.get("ID", ".")

        # Join: cls key is edta_name (matches your example: Name=TE_00002742_INT)
        hit = cls.get(edta_name)

        if hit is None:
            order = superfamily = clade = complete = "."
        else:
            order = hit["Order"]
            superfamily = hit["Superfamily"]
            clade = hit["Clade"]
            complete = hit["Complete"]

        out_lines.append(
            f"{edta_name}\t{seqid}\t{start}\t{end}\t{repeatclass}\t{order}\t{superfamily}\t{clade}\t{complete}"
        )

print("\n".join(out_lines))

##############################
# to run

python3 join_edta_gff3_with_cls.py \
  /scratch/celphin/EDTA/TEsorter/data/Ha412HOv3Chr01.fa.mod.EDTA.TElib.fa.rexdb-plant.cls.tsv \
  /scratch/celphin/EDTA/edta_out/Ha412HOv3Chr01/Ha412HOv3Chr01.fa.mod.EDTA.TEanno.gff3 \
  > TEsorter_annotation.txt


more TEsorter_annotation.txt
# Name    Chr     Start   End     Repeatclass     Order   Superfamily     Clade   Complete
# TE_00002742_INT Ha412HOv3Chr01  1       859     Copia_LTR_retrotransposon       .       .       .       .
# TE_00002742_INT Ha412HOv3Chr01  1060    1462    Copia_LTR_retrotransposon       .       .       .       .
# TE_00002742_INT Ha412HOv3Chr01  1702    3023    Copia_LTR_retrotransposon       .       .       .       .
# TE_00002742_INT Ha412HOv3Chr01  7840    8295    Copia_LTR_retrotransposon       .       .       .       .
# TE_00002742_INT Ha412HOv3Chr01  10401   10594   Copia_LTR_retrotransposon       .       .       .       .
# TE_00002742_INT Ha412HOv3Chr01  14592   15099   Copia_LTR_retrotransposon       .       .       .       .
# TE_00002742_INT Ha412HOv3Chr01  19110   19252   Copia_LTR_retrotransposon       .       .       .       .
# TE_00003645     Ha412HOv3Chr01  20283   21687   L1_LINE_retrotransposon LINE    unknown unknown unknown
# TE_00003039_LTR Ha412HOv3Chr01  178553  180085  Gypsy_LTR_retrotransposon       .       .       .       .
# TE_00002491_LTR Ha412HOv3Chr01  180086  180211  LTR_retrotransposon     LTR     Gypsy   Tekay   no
# TE_00003438_INT Ha412HOv3Chr01  180219  183660  Gypsy_LTR_retrotransposon       LTR     Gypsy   Tekay   no
# TE_00002755_INT Ha412HOv3Chr01  182880  185003  LTR_retrotransposon     LTR     Gypsy   mixture no
# TE_00002491_LTR Ha412HOv3Chr01  184841  185007  LTR_retrotransposon     LTR     Gypsy   Tekay   no
# TE_00003382_LTR Ha412HOv3Chr01  185008  185654  LTR_retrotransposon     .       .       .       .
# TE_00002340_LTR Ha412HOv3Chr01  185255  185730  Gypsy_LTR_retrotransposon       .       .       .       .
# TE_00003382_LTR Ha412HOv3Chr01  185829  186076  LTR_retrotransposon     .       .       .       .
# TE_00003039_LTR Ha412HOv3Chr01  186077  187606  Gypsy_LTR_retrotransposon       .       .       .       .
# TE_00002491_LTR Ha412HOv3Chr01  187607  187733  LTR_retrotransposon     LTR     Gypsy   Tekay   no
# TE_00003438_INT Ha412HOv3Chr01  187741  191181  Gypsy_LTR_retrotransposon       LTR     Gypsy   Tekay   no
# TE_00002755_INT Ha412HOv3Chr01  190401  192524  LTR_retrotransposon     LTR     Gypsy   mixture no
# TE_00002491_LTR Ha412HOv3Chr01  192362  192528  LTR_retrotransposon     LTR     Gypsy   Tekay   no


########################################
# Eventually join data from all chromosomes together

cd /scratch/celphin/EDTA/TEsorter/data/

# make chromosome list
CHR_LIST=(01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17)

mkdir -p per_chr

for c in "${CHR_LIST[@]}"; do
    cls="/scratch/celphin/EDTA/TEsorter/data/Ha412HOv3Chr${c}.fa.mod.EDTA.TElib.fa.rexdb-plant.cls.tsv"
    gff="/scratch/celphin/EDTA/edta_out/Ha412HOv3Chr${c}/Ha412HOv3Chr${c}.fa.mod.EDTA.TEanno.gff3"

    out="per_chr/TEsorter_annotation_chr${c}.txt"

    printf 'Processing chr%s\n' "$c"
    printf '  CLS: %s\n' "$cls"
    printf '  GFF: %s\n' "$gff"

    python3 join_edta_gff3_with_cls.py "$cls" "$gff" > "$out"
done



# join all
out="TEsorter_annotation.ALLchrs.txt"
first=true

for c in "${CHR_LIST[@]}"; do
    f="per_chr/TEsorter_annotation_chr${c}.txt"

    if [[ ! -f "$f" ]]; then
        echo "Warning: missing file: $f" >&2
        continue
    fi

    if $first; then
        cat "$f" > "$out"
        first=false
    else
        tail -n +2 "$f" >> "$out"
    fi
done

##########################################
# Combine the EDTA and TE sorter annotations??

# Name    Chr     Start   End     Repeatclass     Order   Superfamily     Clade   Complete
# TE_00002491_LTR Ha412HOv3Chr01  180086  180211  LTR_retrotransposon     LTR     Gypsy   Tekay   no
# TE_00003438_INT Ha412HOv3Chr01  180219  183660  Gypsy_LTR_retrotransposon       LTR     Gypsy   Tekay   no
# TE_00002755_INT Ha412HOv3Chr01  182880  185003  LTR_retrotransposon     LTR     Gypsy   mixture no
# TE_00002491_LTR Ha412HOv3Chr01  184841  185007  LTR_retrotransposon     LTR     Gypsy   Tekay   no
# TE_00003382_LTR Ha412HOv3Chr01  185008  185654  LTR_retrotransposon     .       .       .       .
# TE_00002340_LTR Ha412HOv3Chr01  185255  185730  Gypsy_LTR_retrotransposon       .       .       .       .
# TE_00003382_LTR Ha412HOv3Chr01  185829  186076  LTR_retrotransposon     .       .       .       .
# TE_00003039_LTR Ha412HOv3Chr01  186077  187606  Gypsy_LTR_retrotransposon       .       .       .       .
# TE_00002491_LTR Ha412HOv3Chr01  187607  187733  LTR_retrotransposon     LTR     Gypsy   Tekay   no
# TE_00003438_INT Ha412HOv3Chr01  187741  191181  Gypsy_LTR_retrotransposon       LTR     Gypsy   Tekay   no
# TE_00002755_INT Ha412HOv3Chr01  190401  192524  LTR_retrotransposon     LTR     Gypsy   mixture no
# TE_00002491_LTR Ha412HOv3Chr01  192362  192528  LTR_retrotransposon     LTR     Gypsy   Tekay   no
# TE_00002179_LTR Ha412HOv3Chr01  192529  192619  LTR_retrotransposon     .       .       .       .
# TE_00002340_LTR Ha412HOv3Chr01  192620  193225  Gypsy_LTR_retrotransposon       .       .       .       .
# TE_00003382_LTR Ha412HOv3Chr01  193324  193571  LTR_retrotransposon     .       .       .       .
