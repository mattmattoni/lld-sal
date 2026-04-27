#!/bin/bash

DATA_DIR="/home/mattonim/psych_oajilore_chi_link/mattonim/rembrandt/data_hcp"
DATALIST="/home/mattonim/psych_oajilore_chi_link/mattonim/lld-sal/logs/data_check.txt"

rm -f "$DATALIST"

echo "subject,fsaverage_LR32k,rest-1,rest-2,msit" > $DATALIST

for subj in $DATA_DIR/*; do
    SUBJ_ID=$(basename $subj)
    if [ "$SUBJ_ID" == "zz_templates" ]; then
        continue
    fi

    # Check each folder
    [ -d "$subj/MNINonLinear/fsaverage_LR32k" ] && FS="yes" || FS="no"
    [ -d "$subj/MNINonLinear/Results/rest-1" ] && R1="yes" || R1="no"
    [ -d "$subj/MNINonLinear/Results/rest-2" ] && R2="yes" || R2="no"
    [ -d "$subj/MNINonLinear/Results/task-MSIT" ] && MSIT="yes" || MSIT="no"

    echo "$SUBJ_ID,$FS,$R1,$R2,$MSIT" >> $DATALIST
done

echo "Results written to $DATALIST"

#Generate sublist

SUBLIST=/home/mattonim/psych_oajilore_chi_link/mattonim/lld-sal/logs/sublist_include.txt

rm -f "$SUBLIST"

tail -n +2 "$DATALIST" | while IFS=',' read -r subj fs r1 r2 msit; do
    
    count=0

    [ "$r1" == "yes" ] && count=$((count+1))
    [ "$r2" == "yes" ] && count=$((count+1))
    [ "$msit" == "yes" ] && count=$((count+1))

    if [ "$fs" == "yes" ] && [ "$count" -ge 2 ]; then
        echo "$subj" >> "$SUBLIST"
    fi

done

echo "Wrote filtered subject list to $SUBLIST"

# summarize sublist 

N=$(wc -l < "$SUBLIST")

CHUNK_SIZE=$(( (N + 4) / 5 ))

echo "Filtered subjects: N = $N"
echo "Chunk ranges:"

START=1
for i in 1 2 3 4 5; do
    END=$(( START + CHUNK_SIZE - 1 ))
    [ "$END" -gt "$N" ] && END=$N

    echo "chunk $i: ${START}-${END}"

    START=$(( END + 1 ))

    [ "$START" -gt "$N" ] && break
done