#!/bin/bash
#SBATCH --job-name=group_avg_cifti
#SBATCH --output=/projects/psych_oajilore_chi/mattonim/lld-sal/logs/GroupAveraging_%j.log
#SBATCH --error=/projects/psych_oajilore_chi/mattonim/lld-sal/logs/GroupAveraging_%j.err
#SBATCH --time=4:00:00
#SBATCH --mem=64G
#SBATCH --cpus-per-task=4
#SBATCH --partition=batch

export PATH=/home/mattonim/workbench/bin_linux64:$PATH

BASE_DIR="/scratch/network/mattonim/pfm_output"
OUTPUT_DIR="/scratch/network/mattonim/pfm_output/group_average"

mkdir -p ${OUTPUT_DIR}

python3 << 'EOF'
import numpy as np
import nibabel as nib
from scipy import stats
import glob

label_files = sorted(glob.glob('/scratch/network/mattonim/pfm_output/*/pfm/Bipartite_PhysicalCommunities+AlgorithmicLabeling.dlabel.nii'))

print(f"Found {len(label_files)} subjects")

all_labels = []
ref_img = None

for f in label_files:
    img = nib.load(f)
    if ref_img is None:
        ref_img = img
    data = img.get_fdata().squeeze().astype(int)
    all_labels.append(data)

all_labels = np.array(all_labels)
print(f"Label array shape: {all_labels.shape}")

mode_labels, _ = stats.mode(all_labels, axis=0, keepdims=False)

out_data = mode_labels.reshape(1, -1)
new_img = nib.Cifti2Image(out_data, header=ref_img.header)
new_img.to_filename('/scratch/network/mattonim/pfm_output/group_average/group_mode_network_labels.dlabel.nii')

print("Saved: group_mode_network_labels.dlabel.nii")
EOF

echo "Complete"