#!/bin/bash

OUTPUT="/home/mattonim/psych_oajilore_chi_link/mattonim/rembrandt/derivatives/NetworkSizes.csv"
BASE_DIR="/home/mattonim/psych_oajilore_chi_link/mattonim/rembrandt"
PFM_DIR="/scratch/network/mattonim/pfm_output"

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

# First pass: collect all unique network names across all subjects
declare -A all_networks

for SUBJ_ID in "${unique_subjects[@]}"; do
    PFM_FILE="$PFM_DIR/$SUBJ_ID/pfm/FunctionalNetworkSizes.txt"
    
    if [ -f "$PFM_FILE" ]; then
        # Read network names from the file (skip header)
        while IFS=$'\t' read -r network value; do
            if [ "$network" != "Network" ]; then
                all_networks["$network"]=1
            fi
        done < "$PFM_FILE"
    fi
done

# Convert to sorted array
networks=($(printf '%s\n' "${!all_networks[@]}" | sort))

# Write header
header="sub"
for network in "${networks[@]}"; do
    header="${header},${network}"
done
echo "$header" > $OUTPUT

# Process each unique subject
for SUBJ_ID in "${unique_subjects[@]}"; do
    PFM_FILE="$PFM_DIR/$SUBJ_ID/pfm/FunctionalNetworkSizes.txt"
    
    row="$SUBJ_ID"
    
    if [ -f "$PFM_FILE" ]; then
        # Create associative array for this subject's networks
        declare -A subject_networks
        
        # Read the file and store values
        while IFS=$'\t' read -r network value; do
            if [ "$network" != "Network" ]; then
                subject_networks["$network"]="$value"
            fi
        done < "$PFM_FILE"
        
        # For each network in our master list, get the value or NA
        for network in "${networks[@]}"; do
            if [ -n "${subject_networks[$network]}" ]; then
                row="${row},${subject_networks[$network]}"
            else
                row="${row},NA"
            fi
        done
        
        unset subject_networks
    else
        # File doesn't exist, fill all network columns with NA
        for network in "${networks[@]}"; do
            row="${row},NA"
        done
    fi
    
    echo "$row" >> $OUTPUT
done

echo "Results written to $OUTPUT"