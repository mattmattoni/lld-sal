#!/bin/bash

OUTPUT="/home/mattonim/psych_oajilore_chi_link/mattonim/lld-sal/logs/data_check.csv"

# Write header
echo "sub,raw_fs,raw_rest1,raw_rest2,cifti_fs,cifti_rest1,cifti_rest2,useable,processed,pfm" > $OUTPUT

BASE_DIR="/home/mattonim/psych_oajilore_chi_link/mattonim/rembrandt"

# Collect all unique subject IDs from all Baseline folders across all sites
declare -A subjects

for SITE in UIC VUMC UPMC; do
    # Get subjects from FS folders
    if [ -d "$BASE_DIR/Baseline-FS-$SITE" ]; then
        for subj_dir in $BASE_DIR/Baseline-FS-$SITE/*; do
            if [ -d "$subj_dir" ]; then
                subjects[$(basename $subj_dir)]=1
            fi
        done
    fi
    
    # Get subjects from REST1 folders
    if [ -d "$BASE_DIR/Baseline-fMRI_REST1-$SITE" ]; then
        for subj_dir in $BASE_DIR/Baseline-fMRI_REST1-$SITE/*; do
            if [ -d "$subj_dir" ]; then
                subjects[$(basename $subj_dir)]=1
            fi
        done
    fi
    
    # Get subjects from REST2 folders
    if [ -d "$BASE_DIR/Baseline-fMRI_REST2-$SITE" ]; then
        for subj_dir in $BASE_DIR/Baseline-fMRI_REST2-$SITE/*; do
            if [ -d "$subj_dir" ]; then
                subjects[$(basename $subj_dir)]=1
            fi
        done
    fi
done

# Process each unique subject
for SUBJ_ID in "${!subjects[@]}"; do
    # Initialize all checks to "no"
    RAW_FS="no"
    RAW_R1="no"
    RAW_R2="no"
    
    # Check raw data across all sites
    for SITE in UIC VUMC UPMC; do
        [ -d "$BASE_DIR/Baseline-FS-$SITE/$SUBJ_ID/surf" ] && RAW_FS="yes"
        [ -d "$BASE_DIR/Baseline-fMRI_REST1-$SITE/$SUBJ_ID/PREPROC" ] && RAW_R1="yes"
        [ -d "$BASE_DIR/Baseline-fMRI_REST2-$SITE/$SUBJ_ID/PREPROC" ] && RAW_R2="yes"
    done
    
    # Check cifti files
    DATA_HCP="$BASE_DIR/data_hcp/$SUBJ_ID"
    [ -d "$DATA_HCP/MNINonLinear/fsaverage_LR32k" ] && CIFTI_FS="yes" || CIFTI_FS="no"
    [ -d "$DATA_HCP/MNINonLinear/Results/rest-1" ] && CIFTI_R1="yes" || CIFTI_R1="no"
    [ -d "$DATA_HCP/MNINonLinear/Results/rest-2" ] && CIFTI_R2="yes" || CIFTI_R2="no"
    
    # Check useable: raw_fs AND (raw_rest1 OR raw_rest2)
    if [ "$RAW_FS" == "yes" ] && { [ "$RAW_R1" == "yes" ] || [ "$RAW_R2" == "yes" ]; }; then
        USEABLE="yes"
    else
        USEABLE="no"
    fi
    
    # Check processed: cifti_fs AND (cifti_rest1 OR cifti_rest2)
    if [ "$CIFTI_FS" == "yes" ] && { [ "$CIFTI_R1" == "yes" ] || [ "$CIFTI_R2" == "yes" ]; }; then
        PROCESSED="yes"
    else
        PROCESSED="no"
    fi
    
    # Check PFM output (corrected to .txt file)
    [ -f "/scratch/network/mattonim/pfm_output/$SUBJ_ID/pfm/FunctionalNetworkSizes.txt" ] && PFM="yes" || PFM="no"
    
    # Write to CSV
    echo "$SUBJ_ID,$RAW_FS,$RAW_R1,$RAW_R2,$CIFTI_FS,$CIFTI_R1,$CIFTI_R2,$USEABLE,$PROCESSED,$PFM" >> $OUTPUT
done

echo "Results written to $OUTPUT"