#!/bin/bash
# @author Adam Pelletier 
# @version 0.1

# read input arguments
email="slim.fourati@emory.edu"
genome=GRCh38
acceptedGenome=("GRCh38")

while getopts :d:e:g:h option
do
    case "${option}" in
    h) echo "Command: bash spaceranger_master.sh -d {fastq/directoryfastq} ..."
        echo "argument: d=[d]irectory with raw data (required)"
        echo "          g=reference [g]enome"
        echo "          h=print [h]elp"
        exit 1;;
    d) dirFastq=$OPTARG;;
    e) email=$OPTARG;;
    g) genome=$OPTARG
        if [[ ! "${acceptedGenome[@]}" =~ "$genome" ]]
        then
        echo "Invalid -g argument: choose between ${acceptedGenome[@]}"
        exit 1
        fi;;
    \?) echo "Invalid option: -$OPTARG"
        exit 1;;
    :)
        echo "Option -$OPTARG requires an argument."
        exit 1;;
    esac
done

# test that directory is provided
if [ -z ${dirFastq+x} ]
then
    echo "error...option -d required."
    exit 1
fi

# test that directory contains seq files
suffix="fq.gz"
nfiles=$(find $dirFastq -name "*_1.$suffix" | wc -l)
if [ $nfiles -lt 1 ]
then
    echo "error...empty input directory"
    exit 1
fi

# initialize directory
dirData=$(echo $dirFastq | sed -r "s|efs/||g")



# modify preprocessing json
sed -ri "s|\"jobName\": \"spaceranger-job-TIMESTAMP\",|\"jobName\": \"spaceranger-job-$(date +%Y%m%d%M%S)\",|g" \
    spaceranger.json
sed -ri "s|\"size\":.+$|\"size\": ${nfiles}|g" \
    spaceranger.json
sed -ri "s|\"-d\",.+$|\"-d\",\"${dirData}\",|g" \
    spaceranger.json
sed -ri "s|\"-g\",.+$|\"-g\",\"${genome}\"|g" \
    spaceranger.json

# lauch preprocessing script
cmd="aws batch submit-job"
cmd="$cmd --cli-input-json file://spaceranger.json"
cmd="$cmd --profile 'tki-aws-account-310-rhedcloud/RHEDcloudAdministratorRole'"

# copy script on mount
cp spaceranger.sh /mnt/efs/

# echo $cmd
eval $cmd
