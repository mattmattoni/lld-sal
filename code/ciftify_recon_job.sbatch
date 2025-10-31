#!/bin/bash

#SBATCH --partition=batch
#SBATCH --job-name=ciftify_recon
#SBATCH --nodes=1
#SBATCH --tasks-per-node=10
#SBATCH --time=4:00:00
#SBATCH --output=/projects/psych_oajilore_chi/mattonim/lld-sal/logs/recon_%j.log
#SBATCH --error=/projects/psych_oajilore_chi/mattonim/lld-sal/logs/recon_%j.e
#SBATCH --mail-user=mattonim@uic.edu

export PATH=$HOME/.local/bin:$PATH

CIFTIFY_IMG=/projects/psych_oajilore_chi/mattonim/tigrlab_fmriprep_ciftify_latest-2019-08-16-454dd291e09f.simg
PROJECT_DIR=/projects/psych_oajilore_chi/mattonim/rembrandt
FS_SITE=REMBRANDT-FS7_v1-Baseline-VUMC 
SUBJECT_ID=14180

mkdir -p /projects/psych_oajilore_chi/mattonim/rembrandt/data_hcp

echo "Running ciftify_recon_all for subject: $SUBJECT_ID"

singularity exec --bind "$PROJECT_DIR":/data --bind /projects/psych_oajilore_chi/mattonim/lld-sal:/githome "$CIFTIFY_IMG" \
  /home/code/ciftify/ciftify/bin/ciftify_recon_all $SUBJECT_ID \
    --fs-subjects-dir /data/"$FS_SITE"/"$SUBJECT_ID" \
    --ciftify-work-dir /data/data_hcp \
    --surf-reg FS \
    --fs-license /githome/license.txt

echo "Done with $SUBJECT_ID"
