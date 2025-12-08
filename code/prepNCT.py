#!/usr/bin/env python3

import pandas as pd
import numpy as np
import nibabel as nib
import scipy.io as sio
import os
import subprocess
from pathlib import Path

# Paths
PFM_BASE = "/scratch/network/mattonim/pfm_output"
DERIVATIVES = "/projects/psych_oajilore_chi/mattonim/lld-sal/derivatives"
INPUT_CSV = os.path.join(DERIVATIVES, "salience_communities.csv")
OUTPUT_CSV = os.path.join(DERIVATIVES, "salience_communities_prep.csv")
NCT_INPUT_DIR = os.path.join(PFM_BASE, "nct_inputs")

# Workbench path
WB_COMMAND = "/home/mattonim/workbench/bin_linux64/wb_command"

# Confidence threshold
CONFIDENCE_THRESHOLD = 0.40

# Create directories
os.makedirs(NCT_INPUT_DIR, exist_ok=True)

print("Loading salience communities data...")
df = pd.read_csv(INPUT_CSV, dtype={'Subject': str})

# Get all subjects
all_subjects = sorted([d.name for d in Path(PFM_BASE).iterdir() if d.is_dir()])

print(f"Found {len(all_subjects)} subjects in PFM output")

# Initialize results
results = []

# Process each subject
for idx, subj in enumerate(all_subjects, 1):
    print(f"\n[{idx}/{len(all_subjects)}] Processing {subj}...")
    
    # Get this subject's salience communities
    subj_data = df[df['Subject'] == subj]
    
    if subj_data.empty:
        print(f"  No salience communities found")
        continue
    
    print(f"  Found {len(subj_data)} salience communities")
    
    # Path to dlabel file
    dlabel_file = os.path.join(PFM_BASE, subj, "pfm", 
                               "Bipartite_PhysicalCommunities+AlgorithmicLabeling.dlabel.nii")
    
    if not os.path.exists(dlabel_file):
        print(f"  WARNING: dlabel file not found")
        continue
    
    # Create subject directory
    subj_nct_dir = os.path.join(NCT_INPUT_DIR, subj)
    os.makedirs(subj_nct_dir, exist_ok=True)
    
    # Process each community
    for _, row in subj_data.iterrows():
        community = row['Community']
        confidence = row['Confidence']
        
        # Only process uncertain communities
        if confidence >= CONFIDENCE_THRESHOLD:
            print(f"  Skipping confident community {community} (Confidence: {confidence:.3f})")
            continue
        
        print(f"  Processing UNCERTAIN community {community} (Confidence: {confidence:.3f})...")
        
        # Extract community to temp dscalar
        temp_dscalar = os.path.join(subj_nct_dir, f"temp_community_{community}.dscalar.nii")
        
        cmd = [
            WB_COMMAND, "-cifti-label-to-roi",
            dlabel_file,
            temp_dscalar,
            "-key", str(community)
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode != 0:
            print(f"    WARNING: Failed to extract community {community}")
            results.append({
                'Subject': subj,
                'Community': community,
                'Network': row['Network'],
                'FC_Similarity': row['FC_Similarity'],
                'Spatial_Score': row['Spatial_Score'],
                'Confidence': confidence,
                'Alt_1_Network': row['Alt_1_Network'],
                'Alt_1_FC_Similarity': row['Alt_1_FC_Similarity'],
                'Alt_1_Spatial_Score': row['Alt_1_Spatial_Score'],
                'nct_input_file': 'NA',
                'config_file': 'NA'
            })
            continue
        
        # Load the dscalar file
        try:
            cifti = nib.load(temp_dscalar)
            
            # Get brain model axis to identify cortex vertices
            brain_model_axis = cifti.header.get_axis(1)
            
            # Extract only cortex data
            lh_indices = []
            rh_indices = []
            
            for idx_bm, (name, slice_bm, brain_model) in enumerate(brain_model_axis.iter_structures()):
                if name == 'CIFTI_STRUCTURE_CORTEX_LEFT':
                    lh_indices = list(range(slice_bm.start, slice_bm.stop))
                elif name == 'CIFTI_STRUCTURE_CORTEX_RIGHT':
                    rh_indices = list(range(slice_bm.start, slice_bm.stop))
            
            # Get data
            data = cifti.get_fdata().squeeze()
            
            # Extract left and right hemisphere cortex only
            lh_data = data[lh_indices].reshape(-1, 1)
            rh_data = data[rh_indices].reshape(-1, 1)
            
            print(f"    Left hemisphere: {len(lh_data)} vertices")
            print(f"    Right hemisphere: {len(rh_data)} vertices")
            
            # Pad to full 32492 vertices if needed (vertices not in the data should be 0)
            lh_full = np.zeros((32492, 1))
            rh_full = np.zeros((32492, 1))
            
            # Get vertex indices from brain model
            lh_vertex_list = brain_model_axis.vertex[lh_indices] if hasattr(brain_model_axis, 'vertex') else list(range(len(lh_data)))
            rh_vertex_list = brain_model_axis.vertex[rh_indices] if hasattr(brain_model_axis, 'vertex') else list(range(len(rh_data)))
            
            lh_full[lh_vertex_list] = lh_data
            rh_full[rh_vertex_list] = rh_data
            
            # Save as .mat file for NCT
            mat_file = os.path.join(subj_nct_dir, f"community_{community}.mat")
            sio.savemat(mat_file, {
                'lh_data': lh_full,
                'rh_data': rh_full
            })
            
            # Remove temp dscalar
            os.remove(temp_dscalar)
            
            print(f"    Created: {mat_file}")
            
            # Create config file
            config_file = os.path.join(subj_nct_dir, f"community_{community}_config.yaml")
            with open(config_file, 'w') as f:
                f.write(f"name: '{subj}_community_{community}'\n")
                f.write("space: 'fs_LR_32k'\n")
                f.write("type: 'Hard'\n")
            
            print(f"    Created config: {config_file}")
            
            # Add to results
            results.append({
                'Subject': subj,
                'Community': community,
                'Network': row['Network'],
                'FC_Similarity': row['FC_Similarity'],
                'Spatial_Score': row['Spatial_Score'],
                'Confidence': confidence,
                'Alt_1_Network': row['Alt_1_Network'],
                'Alt_1_FC_Similarity': row['Alt_1_FC_Similarity'],
                'Alt_1_Spatial_Score': row['Alt_1_Spatial_Score'],
                'nct_input_file': mat_file,
                'config_file': config_file
            })
            
        except Exception as e:
            print(f"    ERROR: {e}")
            if os.path.exists(temp_dscalar):
                os.remove(temp_dscalar)
            continue
    
    print(f"  Completed {subj}")

# Save results to CSV
if results:
    results_df = pd.DataFrame(results)
    results_df.to_csv(OUTPUT_CSV, index=False)
    
    print("\n" + "="*60)
    print("Preparation complete!")
    print(f"Output CSV: {OUTPUT_CSV}")
    print(f"NCT input files: {NCT_INPUT_DIR}")
    print(f"\nTotal uncertain communities extracted: {len(results)}")
    print("="*60)
else:
    print("\nNo uncertain communities found!")