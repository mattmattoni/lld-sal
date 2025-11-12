#!/bin/bash

#SBATCH --partition=batch
#SBATCH --job-name=ciftify_recon
#SBATCH --nodes=1
#SBATCH --ntasks=5
#SBATCH --mem=128G
#SBATCH --time=04:00:00
#SBATCH --output=/projects/psych_oajilore_chi/mattonim/lld-sal/logs/recon_%j.log
#SBATCH --error=/projects/psych_oajilore_chi/mattonim/lld-sal/logs/recon_%j.e


export PATH=$HOME/.local/bin:$PATH
module load parallel/20230722-GCCcore-12.2.0

CIFTIFY_IMG=/projects/psych_oajilore_chi/mattonim/tigrlab_fmriprep_ciftify_latest-2019-08-16-454dd291e09f.simg
PROJECT_DIR=/projects/psych_oajilore_chi/mattonim/rembrandt
FS_SITE=REMBRANDT-FS7_v1-Baseline-VUMC 

mkdir -p /projects/psych_oajilore_chi/mattonim/rembrandt/data_hcp

export CIFTIFY_IMG PROJECT_DIR FS_SITE

process_subject() {
    SUBJECT_ID=$1
    echo "[$(date)] Starting subject: $SUBJECT_ID" >&2
    
    singularity exec --bind "$PROJECT_DIR":/data --bind /projects/psych_oajilore_chi/mattonim/lld-sal:/githome "$CIFTIFY_IMG" \
      /home/code/ciftify/ciftify/bin/ciftify_recon_all $SUBJECT_ID \
        --fs-subjects-dir /data/"$FS_SITE" \
        --ciftify-work-dir /data/data_hcp \
        --surf-reg MSMSulc \
        --fs-license /githome/license.txt
    
    echo "[$(date)] Completed subject: $SUBJECT_ID" >&2
}

export -f process_subject

cd /projects/psych_oajilore_chi/mattonim/rembrandt/$FS_SITE

# Count number of subject directories
NUM_SUBJECTS=$(ls -d [0-9]* 2>/dev/null | wc -l)

# Jobs: NUM_SUBJECTS or 5
PARALLEL_JOBS=$((NUM_SUBJECTS < 5 ? NUM_SUBJECTS : 5))

echo "Found $NUM_SUBJECTS subjects"
echo "Running $PARALLEL_JOBS subjects in parallel"

# Run subjects in parallel
ls -d [0-9]* | parallel --jobs $PARALLEL_JOBS --joblog /projects/psych_oajilore_chi/mattonim/lld-sal/logs/parallel_joblog_${SLURM_JOB_ID}.txt process_subject {}

echo "All $NUM_SUBJECTS subjects completed!"