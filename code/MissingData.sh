#!/bin/bash

DATA_DIR="/home/mattonim/psych_oajilore_chi_link/mattonim/rembrandt/data_hcp"
OUTPUT="/home/mattonim/psych_oajilore_chi_link/mattonim/lld-sal/logs/data_check.txt"

echo "subject,fsaverage_LR32k,rest-1,rest-2" > $OUTPUT

for subj in $DATA_DIR/*; do
    SUBJ_ID=$(basename $subj)
    if [ "$SUBJ_ID" == "zz_templates" ]; then
        continue
    fi

    # Check each folder
    [ -d "$subj/MNINonLinear/fsaverage_LR32k" ] && FS="yes" || FS="no"
    [ -d "$subj/MNINonLinear/Results/rest-1" ] && R1="yes" || R1="no"
    [ -d "$subj/MNINonLinear/Results/rest-2" ] && R2="yes" || R2="no"

    echo "$SUBJ_ID,$FS,$R1,$R2" >> $OUTPUT
done

echo "Results written to $OUTPUT"