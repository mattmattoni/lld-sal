#!/bin/bash

#SBATCH --partition=batch
#SBATCH --job-name=surface-areas
#SBATCH --nodes=1
#SBATCH --ntasks=15
#SBATCH --mem=5G
#SBATCH --time=4:00:00
#SBATCH --output=/projects/psych_oajilore_chi/mattonim/lld-sal/logs/ciftify_func_%j.log
#SBATCH --error=/projects/psych_oajilore_chi/mattonim/lld-sal/logs/ciftify_func_%j.e

export PATH=$HOME/.local/bin:$PATH

DATA_DIR="/home/mattonim/psych_oajilore_chi_link/mattonim/rembrandt/data_hcp"
WB="/home/mattonim/workbench/bin_linux64/wb_command"

MAX_JOBS=15   # match --ntasks
JOBS=0

for subj in $DATA_DIR/*; do
    SUBJ_ID=$(basename $subj)
    if [ "$SUBJ_ID" == "zz_templates" ]; then
        continue
    fi
    echo "Processing subject $SUBJ_ID ..."

    (
    SURF_DIR="$subj/MNINonLinear/fsaverage_LR32k"

    L_SURF="$SURF_DIR/${SUBJ_ID}.L.midthickness.32k_fs_LR.surf.gii"
    R_SURF="$SURF_DIR/${SUBJ_ID}.R.midthickness.32k_fs_LR.surf.gii"

    L_SHAPE="$SURF_DIR/${SUBJ_ID}.L.midthickness_va.32k_fs_LR.shape.gii"
    R_SHAPE="$SURF_DIR/${SUBJ_ID}.R.midthickness_va.32k_fs_LR.shape.gii"
    DCSALAR="$SURF_DIR/${SUBJ_ID}.midthickness_va.32k_fs_LR.dscalar.nii"

    # compute vertex areas if missing
    [ ! -f "$L_SHAPE" ] && $WB -surface-vertex-areas $L_SURF $L_SHAPE
    [ ! -f "$R_SHAPE" ] && $WB -surface-vertex-areas $R_SURF $R_SHAPE

    # merge into a single dscalar
    [ ! -f "$DCSALAR" ] && $WB -cifti-create-dense-scalar $DCSALAR -left-metric $L_SHAPE -right-metric $R_SHAPE

    echo "Subject $SUBJ_ID done."
    ) &

    JOBS=$((JOBS+1))
    if [ "$JOBS" -ge "$MAX_JOBS" ]; then
        wait   # wait for current batch to finish
        JOBS=0
    fi
done

# wait for any remaining background jobs
wait
echo "All subjects processed."
