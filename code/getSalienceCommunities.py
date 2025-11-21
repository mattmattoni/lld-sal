#!/usr/bin/env python3

import pandas as pd
import glob
import os
import sys

# Define paths
PFM_BASE = "/scratch/network/mattonim/pfm_output"
OUTPUT_DIR = "/projects/psych_oajilore_chi/mattonim/lld-sal/derivatives"
OUTPUT_CSV = os.path.join(OUTPUT_DIR, "salience_communities.csv")

# Create output directory
os.makedirs(OUTPUT_DIR, exist_ok=True)

# Get list of subjects
subject_dirs = glob.glob(os.path.join(PFM_BASE, "*/"))
subjects = [os.path.basename(d.rstrip('/')) for d in subject_dirs]

print(f"Processing {len(subjects)} subjects...")

# Initialize list to store results
results = []

# Loop through each subject
for subj in subjects:
    xls_file = os.path.join(PFM_BASE, subj, "pfm", 
                            "Bipartite_PhysicalCommunities+AlgorithmicLabeling_NetworkLabels.xls")
    
    if not os.path.exists(xls_file):
        continue
    
    try:
        df = pd.read_excel(xls_file, engine='xlrd')
        
        # Filter for Salience in Network or Alt_1_Network
        mask = (df['Network'].astype(str).str.contains('Salience', case=False, na=False) |
                df['Alt_1_Network'].astype(str).str.contains('Salience', case=False, na=False))
        
        salience_rows = df[mask].copy()
        
        if not salience_rows.empty:
            salience_rows.insert(0, 'Subject', subj)
            
            columns = ['Subject', 'Community', 'Network', 'FC_Similarity', 
                      'Spatial_Score', 'Confidence', 'Alt_1_Network', 
                      'Alt_1_FC_Similarity', 'Alt_1_Spatial_Score']
            
            results.append(salience_rows[columns])
    
    except Exception as e:
        print(f"Error processing {subj}: {e}")

# Combine and save results
if results:
    final_df = pd.concat(results, ignore_index=True)
    final_df.to_csv(OUTPUT_CSV, index=False)
    print(f"Found {len(final_df)} salience communities across {len(results)} subjects")
    print(f"Output: {OUTPUT_CSV}")
else:
    print("No salience networks found!")
    sys.exit(1)