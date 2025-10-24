#!/bin/bash

#SBATCH --partition=batch
#SBATCH --job-name=ciftify_recon
#SBATCH --nodes=1
#SBATCH --tasks-per-node=10
#SBATCH --time=4:00:00
#SBATCH --output=/projects/psych_oajilore_chi/mattonim/lld-sal/logs/recon_%j.log
#SBATCH --error=/projects/psych_oajilore_chi/mattonim/lld-sal/logs/recon_%j.e
#SBATCH --mail-user=mattonim@uic.edu

rm -f /projects/psych_oajilore_chi/mattonim/lld-sal/logs/recon_*.*

module load apptainer

CIFTIFY_IMG=/projects/psych_oajilore_chi/mattonim/rembrandt_raw/tigrlab_fmriprep_ciftify_latest-2019-08-16-454dd291e09f.simg
PROJECT_DIR=/projects/psych_oajilore_chi/mattonim/rembrandt_raw
HCP_DIR=/projects/psych_oajilore_chi/mattonim/rembrandt_hcp
FS_SITE=REMBRANDT-FS7_v1-Baseline-VUMC 
SUBJECT_ID=REMBRANDT-x-14180-x-14180a-x-FS7_v1-x-d517c7dd


mkdir -p $HCP_DIR

echo "Running ciftify_recon_all for subject: $SUBJECT_ID"

apptainer exec --bind "$PROJECT_DIR":/data "$CIFTIFY_IMG" \
  /home/code/ciftify/ciftify/bin/ciftify_recon_all "$SUBJECT_ID" \
    --fs-subjects-dir /data/"$FS_SITE"/"$SUBJECT_ID" \
    --ciftify-work-dir /data/rembrandt_hcp \
    --surf-reg FS


echo "Done with $SUBJECT_ID"
