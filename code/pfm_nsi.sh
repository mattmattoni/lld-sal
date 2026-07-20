#!/bin/bash
subs=/projects/psych_oajilore_chi/mattonim/lld-sal/logs/sublist_include.txt

while read -r sub; do
  cifti=/scratch/network/mattonim/pfm_output/${sub}/pfm/sub-${sub}_concatenated_32k_fsLR.dtseries.nii
  outdir=./nsi_sub${sub}
  pfm-nsi run \
    --cifti "$cifti" \
    --usability \
    --outdir "$outdir" \
    --prefix sub${sub}
done < "$subs"