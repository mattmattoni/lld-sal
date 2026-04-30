#!/bin/bash
#SBATCH --job-name=group_avg_cifti
#SBATCH --output=/projects/psych_oajilore_chi/mattonim/lld-sal/logs/GroupAveraging_%j.log
#SBATCH --error=/projects/psych_oajilore_chi/mattonim/lld-sal/logs/GroupAveraging_%j.err
#SBATCH --time=4:00:00
#SBATCH --mem=64G
#SBATCH --cpus-per-task=4
#SBATCH --partition=batch

# Set Workbench path
export PATH=/home/mattonim/workbench/bin_linux64:$PATH

# Set paths
BASE_DIR="/scratch/network/mattonim/pfm_output"
OUTPUT_DIR="/scratch/network/mattonim/pfm_output/group_average"
SUBLIST="/home/mattonim/psych_oajilore_chi_link/mattonim/lld-sal/logs/sublist_include.txt"

mkdir -p ${OUTPUT_DIR}

# Read subjects from file
SUBJECTS=($(cat ${SUBLIST} | tr -d '\n' | grep -o '[0-9]\{6\}'))

echo "Found ${#SUBJECTS[@]} subjects"

# File patterns to average
declare -A FILES
FILES[1]="Bipartite_PhysicalCommunities+AlgorithmicLabeling.dlabel.nii"
FILES[2]="Bipartite_PhysicalCommunities+AlgorithmicLabeling_InfoMapCommunities.dlabel.nii"
FILES[3]="Bipartite_PhysicalCommunities+AlgorithmicLabeling_FC_WholeBrain.dtseries.nii"
FILES[4]="Bipartite_PhysicalCommunities+AlgorithmicLabeling_FC_btwn_InfoMapCommunities.dtseries.nii"

# Average dtseries files (FC data)
echo "Averaging dtseries files..."
for key in 3 4; do
    file="${FILES[$key]}"
    echo "Processing: $file"
    
    CMD="wb_command -cifti-average ${OUTPUT_DIR}/group_avg_${file}"
    
    COUNT=0
    for sub in "${SUBJECTS[@]}"; do
        SUBFILE="${BASE_DIR}/${sub}/pfm/${file}"
        if [ -f "$SUBFILE" ]; then
            CMD="$CMD -cifti $SUBFILE"
            ((COUNT++))
        fi
    done
    
    echo "  Including ${COUNT} subjects"
    eval $CMD
    
    if [ $? -eq 0 ]; then
        echo "Success: ${OUTPUT_DIR}/group_avg_${file}"
    else
        echo "ERROR processing $file"
    fi
done

# Process dlabel files (network assignments)
echo "Processing dlabel files..."
for key in 1 2; do
    file="${FILES[$key]}"
    echo ""
    echo "Processing: $file"
    
    SUBFILES=()
    COUNT=0
    for sub in "${SUBJECTS[@]}"; do
        SUBFILE="${BASE_DIR}/${sub}/pfm/${file}"
        if [ -f "$SUBFILE" ]; then
            SUBFILES+=("$SUBFILE")
            ((COUNT++))
        fi
    done
    
    echo "Including ${COUNT} subjects"
    
    if [ ${#SUBFILES[@]} -gt 0 ]; then
        # Create probability map
        PROB_FILE="${OUTPUT_DIR}/group_probability_${file/.dlabel.nii/.dscalar.nii}"
        wb_command -cifti-label-probability \
            ${SUBFILES[@]} \
            ${PROB_FILE}
        
        if [ $? -eq 0 ]; then
            echo "Success: ${PROB_FILE}"
        else
            echo "ERROR creating probability map"
        fi
    fi
done

echo "Files created:"
ls -lh ${OUTPUT_DIR}/group_*.nii 2>/dev/null
