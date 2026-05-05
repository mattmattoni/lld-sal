#!/bin/bash
#SBATCH --job-name=pfm_validate_adjust
#SBATCH --partition=batch
#SBATCH --nodes=1
#SBATCH --ntasks=4
#SBATCH --cpus-per-task=2
#SBATCH --mem=60G
#SBATCH --time=6:00:00
#SBATCH --output=/home/mattonim/psych_oajilore_chi_link/mattonim/lld-sal/logs/pfm_validate_adjust_%j.log
#SBATCH --error=/home/mattonim/psych_oajilore_chi_link/mattonim/lld-sal/logs/pfm_validate_adjust_%j.err

# Step 1: Run NCT Validator
echo "Step 1: Running NCT validation"
python /home/mattonim/psych_oajilore_chi_link/mattonim/lld-sal/code/nct_validator.py

if [ $? -ne 0 ]; then
    echo "ERROR: NCT validation failed"
    exit 1
fi

echo "NCT validation completed"

# Step 2: Update Network Labels files
echo "Step 2: Updating NetworkLabels files with manual decisions"
python /home/mattonim/psych_oajilore_chi_link/mattonim/lld-sal/code/update_network_labels.py

if [ $? -ne 0 ]; then
    echo "ERROR: NetworkLabels update failed"
    exit 1
fi

echo "NetworkLabels files updated"

# Step 3: Run adjusted network processing
echo "Step 3: Running adjusted network processing with MATLAB"

# Set up environment
WB=/home/mattonim/workbench
export LD_LIBRARY_PATH=$WB/libs_linux64:$LD_LIBRARY_PATH
module load matlab/2024b
module load parallel/20230722-GCCcore-12.2.0

# Define paths
MATLAB_SCRIPT=/home/mattonim/psych_oajilore_chi_link/mattonim/lld-sal/code/PFM_adjust_networks.m

export WB LD_LIBRARY_PATH MATLAB_SCRIPT

process_subject() {
    SUBJECT=$1
    echo "[$(date)] Starting subject: $SUBJECT"
    
    matlab -nodisplay -nosplash -r "Subject='$SUBJECT'; try, run('$MATLAB_SCRIPT'); catch ME, disp(ME.message); disp(getReport(ME)); end; exit"
    
    echo "[$(date)] Completed subject: $SUBJECT"
}

export -f process_subject

SUBJECT_LIST=/home/mattonim/psych_oajilore_chi_link/mattonim/lld-sal/logs/sublist_include.txt

echo "Processing all subjects from subject list"

cat "$SUBJECT_LIST" | \
parallel --jobs 4 --line-buffer \
--joblog /home/mattonim/psych_oajilore_chi_link/mattonim/lld-sal/logs/pfm_validate_adjust_joblog_${SLURM_JOB_ID}.txt \
'process_subject {}'

echo "PIPELINE COMPLETED"
echo "Output files:"
echo "Validation results: /home/mattonim/psych_oajilore_chi_link/mattonim/lld-sal/derivatives/validated_assignments.csv"
echo "Validation summary: /home/mattonim/psych_oajilore_chi_link/mattonim/lld-sal/derivatives/validation_summary.txt"
echo "NetworkLabels files: /scratch/network/mattonim/pfm_output/*/pfm/*+ManualDecisions.xls"
echo "Adjusted networks: /scratch/network/mattonim/pfm_output/*/pfm/*_adjusted.*"
