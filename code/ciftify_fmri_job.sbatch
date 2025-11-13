#!/bin/bash

#SBATCH --partition=batch
#SBATCH --job-name=ciftify_func
#SBATCH --nodes=1
#SBATCH --ntasks=15
#SBATCH --mem=128G
#SBATCH --time=8:00:00
#SBATCH --output=/projects/psych_oajilore_chi/mattonim/lld-sal/logs/ciftify_func_%j.log
#SBATCH --error=/projects/psych_oajilore_chi/mattonim/lld-sal/logs/ciftify_func_%j.e

export PATH=$HOME/.local/bin:$PATH
module load parallel/20230722-GCCcore-12.2.0

CIFTIFY_IMG=/projects/psych_oajilore_chi/mattonim/tigrlab_fmriprep_ciftify_latest-2019-08-16-454dd291e09f.simg
PROJECT_DIR=/projects/psych_oajilore_chi/mattonim/rembrandt
FS_SITE=REMBRANDT-FS7_v1-Baseline-VUMC 
FMRI_SITE=Baseline-fMRI_REST1-VUMC 
FUNC_LABEL=rest-1

export CIFTIFY_IMG PROJECT_DIR FS_SITE FMRI_SITE FUNC_LABEL

fmri_process_subject() {
    SUBJECT_ID=$1
    FUNC_NIFTI=$FMRI_SITE/$SUBJECT_ID/PREPROC/wbet_rtaREST.nii.gz

    echo "[$(date)] Starting subject: $SUBJECT_ID"

    singularity exec --bind "$PROJECT_DIR":/data \
                    --bind /projects/psych_oajilore_chi/mattonim/lld-sal:/githome \
                    "$CIFTIFY_IMG" \
    /home/code/ciftify/ciftify/bin/ciftify_subject_fmri \
        /data/"$FUNC_NIFTI" \
        "$SUBJECT_ID" \
        "$FUNC_LABEL" \
        --ciftify-work-dir /data/data_hcp \
        --surf-reg MSMSulc \
        --SmoothingFWHM 6

    echo "[$(date)] Completed subject: $SUBJECT_ID"
}

export -f fmri_process_subject

cd /projects/psych_oajilore_chi/mattonim/rembrandt/$FMRI_SITE

# Count number of subject directories
NUM_SUBJECTS=$(ls -d [0-9]* 2>/dev/null | wc -l)

# Jobs: NUM_SUBJECTS or 15
PARALLEL_JOBS=$((NUM_SUBJECTS < 15 ? NUM_SUBJECTS : 15))

echo "Found $NUM_SUBJECTS subjects"
echo "Running $PARALLEL_JOBS subjects in parallel"

# Run subjects in parallel
ls -d [0-9]* | parallel --jobs $PARALLEL_JOBS --joblog /projects/psych_oajilore_chi/mattonim/lld-sal/logs/parallel_joblog_${SLURM_JOB_ID}.txt fmri_process_subject {}

echo "All $NUM_SUBJECTS subjects completed!"
