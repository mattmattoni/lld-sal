#!/bin/bash
#SBATCH --job-name=prep_nct
#SBATCH --output=/projects/psych_oajilore_chi/mattonim/lld-sal/logs/prep_nct_%j.log
#SBATCH --time=02:00:00
#SBATCH --mem=4G
#SBATCH --partition=batch

WB=/home/mattonim/workbench
export LD_LIBRARY_PATH=$WB/libs_linux64:$LD_LIBRARY_PATH
export PATH=$WB/bin_linux64:$PATH

PFM_BASE="/scratch/network/mattonim/pfm_output"
DERIVATIVES="/projects/psych_oajilore_chi/mattonim/lld-sal/derivatives"
INPUT_CSV="${DERIVATIVES}/salience_communities.csv"
OUTPUT_CSV="${DERIVATIVES}/salience_communities_prep.csv"
NCT_INPUT_DIR="${PFM_BASE}/nct_inputs"

# Confidence threshold
CONFIDENCE_THRESHOLD=0.40

# Create directories
mkdir -p ${NCT_INPUT_DIR}

# Get all subjects from PFM output
ALL_SUBJECTS=$(ls -d ${PFM_BASE}/*/ 2>/dev/null | xargs -n 1 basename | sort)
NUM_SUBJECTS=$(echo "${ALL_SUBJECTS}" | wc -w)

echo "Found ${NUM_SUBJECTS} subjects in PFM output"

# Create CSV header
echo "Subject,Community,Network,FC_Similarity,Spatial_Score,Confidence,Alt_1_Network,Alt_1_FC_Similarity,Alt_1_Spatial_Score,nct_input_file,config_file" > ${OUTPUT_CSV}

# Process each subject
count=0
uncertain_count=0
for SUBJ in ${ALL_SUBJECTS}; do
    count=$((count + 1))
    echo ""
    echo "[${count}/${NUM_SUBJECTS}] Processing ${SUBJ}..."
    
    # Save subject's salience communities to temp file
    TEMP_FILE="/tmp/${SUBJ}_sal.txt"
    grep "^${SUBJ}," ${INPUT_CSV} > ${TEMP_FILE}
    
    if [ ! -s "${TEMP_FILE}" ]; then
        echo "  No salience communities found"
        rm -f ${TEMP_FILE}
        continue
    fi
    
    # Count total salience communities
    NUM_SAL=$(wc -l < ${TEMP_FILE})
    echo "  Found ${NUM_SAL} salience communities"
    
    # Path to subject's dlabel file
    DLABEL_FILE="${PFM_BASE}/${SUBJ}/pfm/Bipartite_PhysicalCommunities+AlgorithmicLabeling.dlabel.nii"
    
    if [ ! -f "${DLABEL_FILE}" ]; then
        echo "  WARNING: dlabel file not found"
        rm -f ${TEMP_FILE}
        continue
    fi
    
    # Create subject directory
    SUBJ_NCT_DIR="${NCT_INPUT_DIR}/${SUBJ}"
    mkdir -p ${SUBJ_NCT_DIR}
    
    # Process each community - ONLY extract if uncertain
    while IFS=',' read -r Subject Community Network FC_Sim Spatial Conf Alt1_Net Alt1_FC Alt1_Spatial; do
        
        # Check if uncertain
        if (( $(echo "${Conf} < ${CONFIDENCE_THRESHOLD}" | bc -l) )); then
            
            echo "  Processing UNCERTAIN community ${Community} (Confidence: ${Conf})..."
            uncertain_count=$((uncertain_count + 1))
            
            # Extract this community
            COMMUNITY_OUTPUT="${SUBJ_NCT_DIR}/community_${Community}.dscalar.nii"
            
            wb_command -cifti-label-to-roi \
                ${DLABEL_FILE} \
                ${COMMUNITY_OUTPUT} \
                -key ${Community} 2>/dev/null
            
            if [ $? -ne 0 ]; then
                echo "    WARNING: Failed to extract"
                echo "${Subject},${Community},${Network},${FC_Sim},${Spatial},${Conf},${Alt1_Net},${Alt1_FC},${Alt1_Spatial},NA,NA" >> ${OUTPUT_CSV}
                continue
            fi
            
            echo "    Created: ${COMMUNITY_OUTPUT}"
            
            # Create config
            CONFIG_FILE="${SUBJ_NCT_DIR}/community_${Community}_config.yaml"
            cat > ${CONFIG_FILE} << EOF
name: '${SUBJ}_community_${Community}'
space: 'fs_LR_32k'
type: 'Hard'
EOF
            
            echo "    Created config: ${CONFIG_FILE}"
            
            # Add to CSV
            echo "${Subject},${Community},${Network},${FC_Sim},${Spatial},${Conf},${Alt1_Net},${Alt1_FC},${Alt1_Spatial},${COMMUNITY_OUTPUT},${CONFIG_FILE}" >> ${OUTPUT_CSV}
        else
            echo "  Skipping confident community ${Community} (Confidence: ${Conf})"
        fi
        
    done < ${TEMP_FILE}
    
    rm -f ${TEMP_FILE}
    echo "  Completed ${SUBJ}"
done


echo "Output CSV: ${OUTPUT_CSV}"
echo "NCT input files: ${NCT_INPUT_DIR}"

echo "Summary:"
TOTAL_EXTRACTED=$(tail -n +2 ${OUTPUT_CSV} 2>/dev/null | wc -l)
echo "Total uncertain communities extracted: ${TOTAL_EXTRACTED}"