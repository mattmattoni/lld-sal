#!/bin/bash

OUTPUT="/home/mattonim/psych_oajilore_chi_link/mattonim/lld-sal/logs/data_check.csv"

# Write header
echo "sub,raw_fs,raw_rest1,raw_rest2,cifti_fs,cifti_rest1,cifti_rest2,useable,processed,pfm" > $OUTPUT

BASE_DIR="/home/mattonim/psych_oajilore_chi_link/mattonim/rembrandt"

# Collect all unique subject IDs from all Baseline folders across all sites
subjects=()

for SITE in UIC VUMC UPMC; do
    # Get subjects from FS folders
    if [ -d "$BASE_DIR/Baseline-FS-$SITE" ]; then
        for subj_dir in $BASE_DIR/Baseline-FS-$SITE/*; do
            if [ -d "$subj_dir" ]; then
                subjects+=("$(basename $subj_dir)")
            fi
        done
    fi
    
    # Get subjects from REST1 folders
    if [ -d "$BASE_DIR/Baseline-fMRI_REST1-$SITE" ]; then
        for subj_dir in $BASE_DIR/Baseline-fMRI_REST1-$SITE/*; do
            if [ -d "$subj_dir" ]; then
                subjects+=("$(basename $subj_dir)")
            fi
        done
    fi
    
    # Get subjects from REST2 folders
    if [ -d "$BASE_DIR/Baseline-fMRI_REST2-$SITE" ]; then
        for subj_dir in $BASE_DIR/Baseline-fMRI_REST2-$SITE/*; do
            if [ -d "$subj_dir" ]; then
                subjects+=("$(basename $subj_dir)")
            fi
        done
    fi
done

# Get unique subjects and sort them numerically
unique_subjects=($(printf '%s\n' "${subjects[@]}" | sort -u | sort -n))

# Process each unique subject
for SUBJ_ID in "${unique_subjects[@]}"; do
    # Initialize all checks to 0
    RAW_FS=0
    RAW_R1=0
    RAW_R2=0
    
    # Check raw data across all sites
    for SITE in UIC VUMC UPMC; do
        [ -d "$BASE_DIR/Baseline-FS-$SITE/$SUBJ_ID/surf" ] && RAW_FS=1
        [ -d "$BASE_DIR/Baseline-fMRI_REST1-$SITE/$SUBJ_ID/PREPROC" ] && RAW_R1=1
        [ -d "$BASE_DIR/Baseline-fMRI_REST2-$SITE/$SUBJ_ID/PREPROC" ] && RAW_R2=1
    done
    
    # Check cifti files
    DATA_HCP="$BASE_DIR/data_hcp/$SUBJ_ID"
    [ -d "$DATA_HCP/MNINonLinear/fsaverage_LR32k" ] && CIFTI_FS=1 || CIFTI_FS=0
    [ -d "$DATA_HCP/MNINonLinear/Results/rest-1" ] && CIFTI_R1=1 || CIFTI_R1=0
    [ -d "$DATA_HCP/MNINonLinear/Results/rest-2" ] && CIFTI_R2=1 || CI