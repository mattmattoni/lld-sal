#!/bin/bash

#SBATCH --partition=batch
#SBATCH --job-name=ciftify_func
#SBATCH --nodes=1
#SBATCH --ntasks=15
#SBATCH --time=4:00:00
#SBATCH --output=/projects/psych_oajilore_chi/mattonim/lld-sal/logs/ciftify_func_%j.log
#SBATCH --error=/projects/psych_oajilore_chi/mattonim/lld-sal/logs/ciftify_func_%j.e

export PATH=$HOME/.local/bin:$PATH

module load parallel/20230722-GCCcore-12.2.0

CIFTIFY_IMG=/projects/psych_oajilore_chi/mattonim/tigrlab_fmriprep_ciftify_latest-2019-08-16-454dd291e09f.simg
PROJECT_DIR=/projects/psych_oajilore_chi/mattonim/rembrandt
FS_SITE=REMBRANDT-FS7_v1-Baseline-VUMC 
FMRI_SITE=Baseline-fMRI_REST1-VUMC 
FUNC_LABEL=rest-1
SUBJECT_ID=14180
FUNC_NIFTI=$FMRI_SITE/$SUBJECT_ID/PREPROC/wbet_rtaREST.nii.gz

export CIFTIFY_IMG PROJECT_DIR FS_SITE

echo "Running ciftify_subject_fmri for subject: $SUBJECT_ID"

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

echo "Done with $SUBJECT_ID"
