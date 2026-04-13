#!/usr/bin/env python3

import pandas as pd
import subprocess
import os
from pathlib import Path

# Paths
PREP_CSV = "/projects/psych_oajilore_chi/mattonim/lld-sal/derivatives/salience_communities_prep.csv"
OUTPUT_CSV = "/projects/psych_oajilore_chi/mattonim/lld-sal/derivatives/salience_communities_NCT_results.csv"
NCT_OUTPUT_BASE = "/scratch/network/mattonim/pfm_output/nct_results"

# Create output directory
os.makedirs(NCT_OUTPUT_BASE, exist_ok=True)

print("Loading prepared communities...")
df = pd.read_csv(PREP_CSV)

# Filter to only successfully extracted communities (have valid nct_input_file)
valid_communities = df[df['nct_input_file'] != 'NA'].copy()

print(f"Found {len(valid_communities)} cortical communities ready for NCT analysis")
print(f"Skipping {len(df) - len(valid_communities)} subcortical-only communities")

# Initialize results
results = []

# Process each community
for counter, (idx, row) in enumerate(valid_communities.iterrows(), 1):
    print(f"[{counter}/{len(valid_communities)}]")
    subj = row['Subject']
    comm = row['Community']
    mat_file = row['nct_input_file']
    config_file = row['config_file']
        
    # Create output directory for this community
    comm_output_dir = os.path.join(NCT_OUTPUT_BASE, f"{subj}_comm{comm}")
    os.makedirs(comm_output_dir, exist_ok=True)
    
    # Run NCT using Python API
    try:
        # Create NCT analysis script
        nct_script = f"""
import sys
sys.path.insert(0, '/home/mattonim/.local/lib/python3.9/site-packages')

try:
    from cbig_network_correspondence.network_correspondence import NetworkCorrespondence
    
    nct = NetworkCorrespondence()
    
    # Run correspondence analysis
    results = nct.compute_correspondence(
        input_file='{mat_file}',
        config_file='{config_file}',
        atlas_list=['Gordon2017-17', 'Yeo2011-17'],
        output_dir='{comm_output_dir}'
    )
    
    print("NCT_SUCCESS")
    
except Exception as e:
    print(f"NCT_ERROR: {{e}}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
"""
        
        temp_script = f"/tmp/nct_run_{subj}_{comm}.py"
        with open(temp_script, 'w') as f:
            f.write(nct_script)
        
        # Run NCT
        result = subprocess.run(
            ['python3', temp_script],
            capture_output=True,
            text=True,
            timeout=300  # 5 minute timeout per community
        )
        
        # Clean up temp script
        os.remove(temp_script)
        
        if "NCT_SUCCESS" in result.stdout:
            print(f"  ✓ NCT analysis complete")
            
            # Parse results from output files
            gordon_dice = yeo_dice = 'NA'
            gordon_p = yeo_p = 'NA'
            gordon_net = yeo_net = 'NA'
            
            # Look for summary CSV files
            for csv_file in Path(comm_output_dir).glob("*summary*.csv"):
                try:
                    res_df = pd.read_csv(csv_file)
                    
                    # Check available columns
                    if 'Network' not in res_df.columns or 'Dice' not in res_df.columns:
                        continue
                    
                    # Gordon2017 results
                    if 'Gordon' in csv_file.name:
                        sal_rows = res_df[res_df['Network'].str.contains('Salience|Cingulo', case=False, na=False)]
                        if not sal_rows.empty:
                            best = sal_rows.loc[sal_rows['Dice'].idxmax()]
                            gordon_dice = f"{best['Dice']:.4f}"
                            gordon_p = f"{best['p_value']:.4f}" if 'p_value' in best else 'NA'
                            gordon_net = best['Network']
                    
                    # Yeo2011 results
                    elif 'Yeo' in csv_file.name:
                        sal_rows = res_df[res_df['Network'].str.contains('Salience|Ventral', case=False, na=False)]
                        if not sal_rows.empty:
                            best = sal_rows.loc[sal_rows['Dice'].idxmax()]
                            yeo_dice = f"{best['Dice']:.4f}"
                            yeo_p = f"{best['p_value']:.4f}" if 'p_value' in best else 'NA'
                            yeo_net = best['Network']
                except Exception as e:
                    print(f"    Warning: Could not parse {csv_file.name}: {e}")
                    continue
            
            results.append({
                'Subject': subj,
                'Community': comm,
                'Network': row['Network'],
                'FC_Similarity': row['FC_Similarity'],
                'Spatial_Score': row['Spatial_Score'],
                'Confidence': row['Confidence'],
                'Alt_1_Network': row['Alt_1_Network'],
                'Gordon2017_max_dice': gordon_dice,
                'Gordon2017_p_value': gordon_p,
                'Gordon2017_best_network': gordon_net,
                'Yeo2011_max_dice': yeo_dice,
                'Yeo2011_p_value': yeo_p,
                'Yeo2011_best_network': yeo_net,
                'NCT_status': 'Complete'
            })
            
        else:
            print(f"  ✗ NCT analysis failed")
            print(f"    Error: {result.stderr[:200] if result.stderr else result.stdout[:200]}")
            
            results.append({
                'Subject': subj,
                'Community': comm,
                'Network': row['Network'],
                'FC_Similarity': row['FC_Similarity'],
                'Spatial_Score': row['Spatial_Score'],
                'Confidence': row['Confidence'],
                'Alt_1_Network': row['Alt_1_Network'],
                'Gordon2017_max_dice': 'NA',
                'Gordon2017_p_value': 'NA',
                'Gordon2017_best_network': 'NA',
                'Yeo2011_max_dice': 'NA',
                'Yeo2011_p_value': 'NA',
                'Yeo2011_best_network': 'NA',
                'NCT_status': f'Error'
            })
    
    except subprocess.TimeoutExpired:
        print(f"  ✗ NCT analysis timed out")
        results.append({
            'Subject': subj,
            'Community': comm,
            'Network': row['Network'],
            'FC_Similarity': row['FC_Similarity'],
            'Spatial_Score': row['Spatial_Score'],
            'Confidence': row['Confidence'],
            'Alt_1_Network': row['Alt_1_Network'],
            'Gordon2017_max_dice': 'NA',
            'Gordon2017_p_value': 'NA',
            'Gordon2017_best_network': 'NA',
            'Yeo2011_max_dice': 'NA',
            'Yeo2011_p_value': 'NA',
            'Yeo2011_best_network': 'NA',
            'NCT_status': 'Timeout'
        })
    
    except Exception as e:
        print(f"  ✗ Error: {e}")
        results.append({
            'Subject': subj,
            'Community': comm,
            'Network': row['Network'],
            'FC_Similarity': row['FC_Similarity'],
            'Spatial_Score': row['Spatial_Score'],
            'Confidence': row['Confidence'],
            'Alt_1_Network': row['Alt_1_Network'],
            'Gordon2017_max_dice': 'NA',
            'Gordon2017_p_value': 'NA',
            'Gordon2017_best_network': 'NA',
            'Yeo2011_max_dice': 'NA',
            'Yeo2011_p_value': 'NA',
            'Yeo2011_best_network': 'NA',
            'NCT_status': f'Error: {str(e)}'
        })
    
    # Save intermediate results every 10 communities
    if len(results) % 10 == 0:
        temp_df = pd.DataFrame(results)
        temp_df.to_csv(OUTPUT_CSV + '.tmp', index=False)

# Save final results
if results:
    results_df = pd.DataFrame(results)
    results_df.to_csv(OUTPUT_CSV, index=False)
    
    print("\n" + "="*60)
    print("NCT Analysis Complete!")
    print(f"Total communities analyzed: {len(results)}")
    print(f"Successful: {len([r for r in results if r['NCT_status'] == 'Complete'])}")
    print(f"Output: {OUTPUT_CSV}")
    print("="*60)
else:
    print("\nNo results generated!")