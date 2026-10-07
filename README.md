# Ha412HO T2T V3 Assembly Scripts


The [ASSEMBLY](https://github.com/ericgonzalezs/Ha412_T2T/tree/main/ASSEMBLY) folder has the scripts used to run hifiams, perform the Hi-C alignments with [Juicer](https://github.com/aidenlab/juicer) and run [YHAHS](https://github.com/c-zhou/yahs)

You can find [here](https://github.com/ericgonzalezs/ASSEMBLIES/tree/main) the instructions we used to install and set up the 3D-DNA pipeline from [Aiden Lab](https://github.com/aidenlab)

The [MANUALCURATION](https://github.com/ericgonzalezs/Ha412_T2T/tree/main/MANUALCURATION) contains the steps we followed to prepare the files for visualization in Juicebox and to correct the FASTA file.

The [GAPFILLING](https://github.com/ericgonzalezs/Ha412_T2T/tree/main/GAPFILLING) folder contains all the scripts we used to extract Nanopore sequences for filling gaps in the HiFi assembly and to add telomeric sequences.
The [Gap_filling_and_telomeres.sh](https://github.com/ericgonzalezs/Ha412_T2T/blob/main/GAPFILLING/Gap_filling_and_telomeres.sh) script shows the complete pipeline and how we used the different scripts.

A script that may be particularly useful to the community is [Pysam_semiauto.py](https://github.com/ericgonzalezs/Ha412_T2T/blob/main/GAPFILLING/Pysam_semiauto.py) This script was used to extract Nanopore sequences that could be used to fill gaps in the HiFi assembly based on assembly alignments generated with [Anchorwave](https://github.com/ericgonzalezs/Ha412_T2T/blob/main/GAPFILLING/Anchorwave.sh) and [minimap2](https://github.com/ericgonzalezs/Ha412_T2T/blob/main/GAPFILLING/minimap2.sh).







describir cada carpeta, poner enfásis a los archivos .py y el pipeline completo de FILLGAPS

Poner el link a como instalé y use el pipeline de 3D-DNA
