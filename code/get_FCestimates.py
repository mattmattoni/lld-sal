#!/usr/bin/env python3

import os
import pandas as pd
import numpy as np

FC_DIR = '/scratch/network/mattonim/pfm_output/connectivity_results_month16'
OUTPUT_DIR = '/home/mattonim/psych_oajilore_chi_link/mattonim/lld-sal/derivatives'

def extract_upper_triangle(df):
    """Extract upper triangle of FC matrix as dict of pair:value"""
    fc_dict = {}
    n = len(df)
    for i in range(n):
        for j in range(i+1, n):
            pair_name = f"{df.index[i]}-{df.columns[j]}"
            fc_dict[pair_name] = df.iloc[i, j]
    return fc_dict

def create_summary(fc_type):
    # Get all subject files
    files = sorted([f for f in os.listdir(FC_DIR) if f.endswith(f'{fc_type}_FC.csv')])
    
    if not files:
        print(f"No {fc_type} files found")
        return
    
    # First pass: collect all possible pairs
    all_pairs = set()
    for f in files:
        fc_df = pd.read_csv(os.path.join(FC_DIR, f), index_col=0)
        fc_dict = extract_upper_triangle(fc_df)
        all_pairs.update(fc_dict.keys())
    
    all_pairs = sorted(all_pairs)
    print(f"{fc_type}: {len(all_pairs)} unique pairs across {len(files)} subjects")
    
    # Second pass: extract values for each subject
    all_data = []
    for f in files:
        subject_id = f.split('_')[0]
        fc_df = pd.read_csv(os.path.join(FC_DIR, f), index_col=0)
        fc_dict = extract_upper_triangle(fc_df)
        
        # Match to master list, fill NA for missing
        values = [fc_dict.get(pair, np.nan) for pair in all_pairs]
        all_data.append([subject_id] + values)
    
    # Create summary dataframe
    summary_df = pd.DataFrame(all_data, columns=['Subject'] + all_pairs)
    
    # Save
    output_file = os.path.join(OUTPUT_DIR, f'{fc_type}_FC_summary_month16.txt')
    summary_df.to_csv(output_file, sep='\t', index=False)
    
    print(f"Saved: {output_file}\n")

print("Creating summary files...\n")
create_summary('Network-Network')
create_summary('Comprehensive')
print("\nDone!")