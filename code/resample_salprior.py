#!/usr/bin/env python3
"""Convert salience .mat files to GIFTI and resample to fs_LR_32k"""

import numpy as np
import scipy.io as sio
import nibabel as nib
import subprocess
import os

sphere_dir = '/scratch/network/mattonim/sphere_files'
os.chdir(sphere_dir)

# Load the .mat files
lh_data = sio.loadmat('lh_salience.mat')['lh_salience'].squeeze().astype(np.float32)
rh_data = sio.loadmat('rh_salience.mat')['rh_salience'].squeeze().astype(np.float32)

print(f"Loaded lh: {lh_data.shape}, rh: {rh_data.shape}")

# Create GIFTI files
lh_gii = nib.gifti.GiftiImage()
lh_gii.add_gifti_data_array(nib.gifti.GiftiDataArray(lh_data))
nib.save(lh_gii, 'lh_salience.func.gii')

rh_gii = nib.gifti.GiftiImage()
rh_gii.add_gifti_data_array(nib.gifti.GiftiDataArray(rh_data))
nib.save(rh_gii, 'rh_salience.func.gii')

print("GIFTI files created!")

# Resample with workbench
wb = os.path.expanduser('~/workbench/bin_linux64/wb_command')

# Left hemisphere
print("Resampling left hemisphere...")
subprocess.run([
    wb, '-metric-resample',
    'lh_salience.func.gii',
    'fsaverage5_std_sphere.L.10k_fsavg_L.surf.gii',
    'fs_LR-deformed_to-fsaverage.L.sphere.32k_fs_LR.surf.gii',
    'ADAP_BARY_AREA',
    'lh_salience_32k.func.gii'
], check=True)

# Right hemisphere
print("Resampling right hemisphere...")
subprocess.run([
    wb, '-metric-resample',
    'rh_salience.func.gii',
    'fsaverage5_std_sphere.R.10k_fsavg_R.surf.gii',
    'fs_LR-deformed_to-fsaverage.R.sphere.32k_fs_LR.surf.gii',
    'ADAP_BARY_AREA',
    'rh_salience_32k.func.gii'
], check=True)

print("\nDone! Created:")
print("  lh_salience_32k.func.gii")
print("  rh_salience_32k.func.gii")