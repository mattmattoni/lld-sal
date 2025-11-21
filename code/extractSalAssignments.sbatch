#!/bin/bash
#SBATCH --job-name=extract_salience
#SBATCH --output=/projects/psych_oajilore_chi/mattonim/lld-sal/logs/extract_salience_%j.log
#SBATCH --time=01:00:00
#SBATCH --mem=4G
#SBATCH --partition=short

# Define paths
PFM_BASE="/scratch/network/mattonim/pfm_output"
OUTPUT_DIR="/projects/psych_oajilore_chi/mattonim/lld-sal/derivatives"
OUTPUT_CSV="${OUTPUT_DIR}/salience_communities_summary.csv"
TEMP_FILE="${OUTPUT_DIR}/temp_salience.txt"

# Create output directory
mkdir -p ${OUTPUT_DIR}

# Get subjects
SUBJECTS=$(ls -d ${PFM_BASE}/*/ 2>/dev/null | xargs -n 1 basename)

# Create header
echo "Subject,Community,Network,FC_Similarity,Spatial_Score,Confidence,Alt_1_Network,Alt_1_FC_Similarity,Alt_1_Spatial_Score" > ${OUTPUT_CSV}

# Clear temp file
> ${TEMP_FILE}

echo "Processing ${SUBJECTS} subjects..."

# Process each subject
for SUBJ in ${SUBJECTS}; do
    XLS_FILE="${PFM_BASE}/${SUBJ}/pfm/Bipartite_PhysicalCommunities+AlgorithmicLabeling_NetworkLabels.xls"
    
    if [ -f "${XLS_FILE}" ]; then
        awk -F'\t' -v subj="${SUBJ}" 'NR > 1 && ($2 ~ /Salience/ || $7 ~ /Salience/) {
            printf "%s,%s,%s,%s,%s,%s,%s,%s,%s\n", subj, $1, $2, $3, $4, $5, $7, $8, $9
        }' "${XLS_FILE}" >> ${TEMP_FILE}
    fi
done

# Combine results
cat ${TEMP_FILE} >> ${OUTPUT_CSV}
rm -f ${TEMP_FILE}

echo "Complete! Output: ${OUTPUT_CSV}"