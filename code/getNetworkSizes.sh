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

# Define network names in alphabetical order (as they appear in the files)
networks=(
    "Auditory"
    "CinguloOpercular/Action-mode"
    "Default_Retrosplenial"
    "DorsalAttention"
    "MedialParietal"
    "Premotor/DorsalAttentionII"
    "Salience"
    "Somatomotor_Face"
    "Somatomotor_Foot"
    "Visual_Dorsal/VentralStream"
    "Visual_Lateral"
    "Visual_V1"
    "Visual_V5"
)

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
        # File exists, extract values for each network
        for network in "${networks[@]}"; do
            # Escape special characters in network name for grep
            escaped_network=$(echo "$network" | sed 's/[\/]/\\&/g')
            value=$(grep "^${escaped_network}" "$PFM_FILE" | awk '{print $2}')
            
            if [ -z "$value" ]; then
                row="${row},NA"
            else
                row="${row},${value}"
            fi
        done
    else
        # File doesn't exist, fill all network columns with NA
        for network in "${networks[@]}"; do
            row="${row},NA"
        done
    fi
    
    echo "$row" >> $OUTPUT
done

echo "Results written to $OUTPUT"