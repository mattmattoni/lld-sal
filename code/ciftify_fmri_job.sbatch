#!/bin/bash

#SBATCH --partition=batch
#SBATCH --job-name=ciftify_func_5mm
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=10
#SBATCH --time=4:00:00
#SBATCH --output=/projects/psych_oajilore_chi/mattonim/lld-sal/logs/ciftify_func_%j.log
#SBATCH --error=/projects/psych_oajilore_chi/mattonim/lld-sal/logs/ciftify_func_%j.e
#SBATCH --mail-user=mattonim@uic.edu

export PATH=$HOME/.local/bin:$PATH

CIFTIFY_IMG=/projects/psych_oajilore_chi/mattonim/tigrlab_fmriprep_ciftify_latest-2019-08-16-454dd291e09f.simg
PROJECT_DIR=/projects/psych_oajilore_chi/mattonim/rembrandt
FMRI_SITE=Baseline-fMRI_REST1-VUMC 
SUBJECT_ID=14180
FUNC_NIFTI=/func_preproc.nii.gz

echo "Running ciftify_subject_fmri for subject: $SUBJECT_ID"

singularity exec --bind "$PROJECT_DIR":/data \
                 --bind /projects/psych_oajilore_chi/mattonim/lld-sal:/githome \
                 "$CIFTIFY_IMG" \
  /home/code/ciftify/ciftify/bin/ciftify_subject_fmri \
    "$FUNC_NIFTI" \
    "$SUBJECT_ID" \
    "$FUNC_LABEL" \
    --fs-subjects-dir /data/"$FMRI_SITE" \
    --ciftify-work-dir /data/data_hcp \
    --surf-reg FS \
    --smoothing-fwhm 5 \
    --n_cpus 10 \
    --fs-license /githome/license.txt

echo "Done with $SUBJECT_ID"
