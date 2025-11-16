#!/bin/bash
#SBATCH --job-name=pfm_batch
#SBATCH --partition=batch
#SBATCH --nodes=1
#SBATCH --ntasks=2
#SBATCH --cpus-per-task=6
#SBATCH --mem=180G
#SBATCH --time=24:00:00
#SBATCH --output=/home/mattonim/psych_oajilore_chi_link/mattonim/lld-sal/logs/pfm_batch_%j.log
#SBATCH --error=/home/mattonim/psych_oajilore_chi_link/mattonim/lld-sal/logs/pfm_batch_%j.err

# Set up environment
WB=/home/mattonim/workbench
export LD_LIBRARY_PATH=$WB/libs_linux64:$LD_LIBRARY_PATH
module load matlab/2024b
module load parallel/20230722-GCCcore-12.2.0

# Define paths
DATA_DIR=/home/mattonim/psych_oajilore_chi_link/mattonim/rembrandt/data_hcp
MATLAB_SCRIPT=/home/mattonim/psych_oajilore_chi_link/mattonim/lld-sal/code/PFM_batch.m

export WB LD_LIBRARY_PATH MATLAB_SCRIPT

process_subject() {
    SUBJECT=$1
    echo "[$(date)] Starting subject: $SUBJECT"
    
    matlab -nodisplay -nosplash -r "Subject='$SUBJECT'; try, run('$MATLAB_SCRIPT'); catch ME, disp(ME.message); disp(getReport(ME)); end; exit"
    
    echo "[$(date)] Completed subject: $SUBJECT"
}

export -f process_subject

SUBJECT_LIST=/home/mattonim/psych_oajilore_chi_link/mattonim/lld-sal/logs/sublist.txt
START_LINE=46
END_LINE=90

echo "Processing subjects $START_LINE-$END_LINE from subject list"

sed -n "${START_LINE},${END_LINE}p" $SUBJECT_LIST | parallel --jobs 2 --line-buffer --joblog /home/mattonim/psych_oajilore_chi_link/mattonim/lld-sal/logs/pfm_parallel_joblog_${SLURM_JOB_ID}.txt 'process_subject {}'

echo "All subjects completed!"