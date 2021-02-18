#!/bin/bash
# @author Adam Pelletier
# @version 0.1

# read arguments
while getopts d:g: option
do
    case "$option" in
    d) dirData=$OPTARG;;
    g) genome=$OPTARG;;
    esac
done

# set global variables for the script
seqDependencies="/mnt/efs/genome/$genome/spaceranger"


# identify sample of interest
fastq=$(find $dirData -maxdepth 1 -name '*_1.fq.gz')
fastq=( $(echo $fastq | \
          tr ' ' '\n' | \
          sort | \
          uniq) )
fastq=${fastq[$AWS_BATCH_JOB_ARRAY_INDEX]}
sample=$(echo $fastq | sed -r "s|_1.fq.gz||g")



flag=true
if $flag
then
    # change to directory
    cd $fastqDir
    
    # remove trailing back slash 
    sampleID=$(echo $fastqDir | sed -r 's|/$||g')
    sampleID=$(echo $sampleID | sed -r 's|.+/||g')
    spaceranger count --id=$sample \
                   --transcriptome=$genomeDir/$genome/cellranger \
                   --fastqs=$fastqDir  \
                   --sample=$sample \
                   --image=$dirData/$sample.tif \
                   --slide=V19J01-123 \
                   --area=A1 \
                   --localcores=32 \
                   --localmem=128
    cellranger count \
        --id=$sampleID \
        --transcriptome=$genomeDir/$genome/cellranger/$genome \
        --fastqs=$fastqDir \
        --sample=$sampleID \
        --localcores=32 \
        --expect-cells=10000 \
        --localmem=185 \
        --nosecondary
fi
