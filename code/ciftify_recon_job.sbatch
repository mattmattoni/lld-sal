#!/bin/bash

#SBATCH --partition=batch
#SBATCH --job-name=ciftify_recon
#SBATCH --nodes=1
#SBATCH --ntasks=12
#SBATCH --mem=128G
#SBATCH --time=24:00:00
#SBATCH --output=/projects/psych_oajilore_chi/mattonim/lld-sal/logs/recon_%j.log
#SBATCH --error=/projects/psych_oajilore_chi/mattonim/lld-sal/logs/recon_%j.e

export PATH=$HOME/.local/bin:$PATH
module load parallel/20230722-GCCcore-12.2.0

CIFTIFY_IMG=/projects/psych_oajilore_chi/mattonim/tigrlab_fmriprep_ciftify_latest-2019-08-16-454dd291e09f.simg
PROJECT_DIR=/projects/psych_oajilore_chi/mattonim/rembrandt
SITES=(UIC VUMC UPMC)

mkdir -p /projects/psych_oajilore_chi/mattonim/rembrandt/data_hcp

for SITE in "${SITES[@]}"; do

  FS_SITE=Baseline-FS-$SITE
  export CIFTIFY_IMG PROJECT_DIR FS_SITE

  process_subject() {
      SUBJECT_ID=$1
      echo "[$(date)] Starting subject: $SUBJECT_ID"
      
      singularity exec --bind "$PROJECT_DIR":/data --bind /projects/psych_oajilore_chi/mattonim/lld-sal:/githome "$CIFTIFY_IMG" \
        /home/code/ciftify/ciftify/bin/ciftify_recon_all $SUBJECT_ID \
          --fs-subjects-dir /data/"$FS_SITE" \
          --ciftify-work-dir /data/data_hcp \
          --surf-reg MSMSulc \
          --fs-license /githome/license.txt
      
      echo "[$(date)] Completed subject: $SUBJECT_ID"
  }

  export -f process_subject

  cd /projects/psych_oajilore_chi/mattonim/rembrandt/$FS_SITE

  echo "Found $(ls -d [0-9]* 2>/dev/null | wc -l) subjects"

  ls -d [0-9]* | parallel --jobs 12 --line-buffer --joblog /projects/psych_oajilore_chi/mattonim/lld-sal/logs/parallel_joblog_${SITE}_${SLURM_JOB_ID}.txt 'process_subject {}'

  echo "All subjects completed!"

done