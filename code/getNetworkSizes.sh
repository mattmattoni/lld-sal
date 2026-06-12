#!/bin/bash

OUTPUT="/home/mattonim/psych_oajilore_chi_link/mattonim/rembrandt/derivatives/NetworkSizes_month08.csv"
OUTPUT_ADJUSTED="/home/mattonim/psych_oajilore_chi_link/mattonim/rembrandt/derivatives/NetworkSizes_adjusted_month08.csv"
BASE_DIR="/home/mattonim/psych_oajilore_chi_link/mattonim/rembrandt"
PFM_DIR="/scratch/network/mattonim/pfm_output"

# Collect all unique subject IDs
SUBLIST="/home/mattonim/psych_oajilore_chi_link/mattonim/lld-sal/logs/sublist_include.txt"

# Read subjects from include list, skip blank lines
mapfile -t unique_subjects < <(grep -v '^[[:space:]]*$' "$SUBLIST")

# First pass: collect all unique network names across all subjects (from both original and adjusted)
declare -A all_networks

for SUBJ_ID in "${unique_subjects[@]}"; do
    PFM_FILE="$PFM_DIR/$SUBJ_ID/pfm-08/FunctionalNetworkSizes.txt"
    PFM_FILE_ADJ="$PFM_DIR/$SUBJ_ID/pfm-08/FunctionalNetworkSizes_adjusted.txt"
    
    # Read from original file
    if [ -f "$PFM_FILE" ]; then
        while IFS=$'\t' read -r network value; do
            if [ "$network" != "Network" ]; then
                all_networks["$network"]=1
            fi
        done < "$PFM_FILE"
    fi
    
    # Read from adjusted file
    if [ -f "$PFM_FILE_ADJ" ]; then
        while IFS=$'\t' read -r network value; do
            if [ "$network" != "Network" ]; then
                all_networks["$network"]=1
            fi
        done < "$PFM_FILE_ADJ"
    fi
done

# Convert to sorted array
networks=($(printf '%s\n' "${!all_networks[@]}" | sort))

# Write headers for both files
header="sub"
for network in "${networks[@]}"; do
    header="${header},${network}"
done
echo "$header" > $OUTPUT
echo "$header" > $OUTPUT_ADJUSTED

# Process each unique subject
for SUBJ_ID in "${unique_subjects[@]}"; do
    PFM_FILE="$PFM_DIR/$SUBJ_ID/pfm-08/FunctionalNetworkSizes.txt"
    PFM_FILE_ADJ="$PFM_DIR/$SUBJ_ID/pfm-08/FunctionalNetworkSizes_adjusted.txt"
    
    row_orig="$SUBJ_ID"
    row_adj="$SUBJ_ID"
    
    # Process original file
    if [ -f "$PFM_FILE" ]; then
        declare -A subject_networks
        
        while IFS=$'\t' read -r network value; do
            if [ "$network" != "Network" ]; then
                subject_networks["$network"]="$value"
            fi
        done < "$PFM_FILE"
        
        for network in "${networks[@]}"; do
            if [ -n "${subject_networks[$network]}" ]; then
                row_orig="${row_orig},${subject_networks[$network]}"
            else
                row_orig="${row_orig},NA"
            fi
        done
        
        unset subject_networks
    else
        for network in "${networks[@]}"; do
            row_orig="${row_orig},NA"
        done
    fi
    
    # Process adjusted file
    if [ -f "$PFM_FILE_ADJ" ]; then
        declare -A subject_networks_adj
        
        while IFS=$'\t' read -r network value; do
            if [ "$network" != "Network" ]; then
                subject_networks_adj["$network"]="$value"
            fi
        done < "$PFM_FILE_ADJ"
        
        for network in "${networks[@]}"; do
            if [ -n "${subject_networks_adj[$network]}" ]; then
                row_adj="${row_adj},${subject_networks_adj[$network]}"
            else
                row_adj="${row_adj},NA"
            fi
        done
        
        unset subject_networks_adj
    else
        for network in "${networks[@]}"; do
            row_adj="${row_adj},NA"
        done
    fi
    
    echo "$row_orig" >> $OUTPUT
    echo "$row_adj" >> $OUTPUT_ADJUSTED
done

echo "Original network sizes written to $OUTPUT"
echo "Adjusted network sizes written to $OUTPUT_ADJUSTED"