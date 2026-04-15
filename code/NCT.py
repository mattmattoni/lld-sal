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
    import cbig_network_correspondence as cnc

    ref_params = cnc.compute_overlap_with_atlases.DataParams(
        '{config_file}',
        '{mat_file}'
    )

    cnc.compute_overlap_with_atlases.network_correspondence(
        ref_params,
        ['EG17', 'TY17'],
        '{comm_output_dir}'
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
            timeout=300
        )

        # Clean up temp script
        os.remove(temp_script)

        if "NCT_SUCCESS" in result.stdout:
            print(f"  ✓ NCT analysis complete")

            result_row = {
                'Subject': subj,
                'Community': comm,
                'Network': row['Network'],
                'FC_Similarity': row['FC_Similarity'],
                'Spatial_Score': row['Spatial_Score'],
                'Confidence': row['Confidence'],
                'Alt_1_Network': row['Alt_1_Network'],
                'NCT_status': 'Complete'
            }

            for csv_file in Path(comm_output_dir).glob("*.csv"):
                try:
                    res_df = pd.read_csv(csv_file)

                    if 'group' not in res_df.columns or 'dice' not in res_df.columns:
                        continue

                    # Add dice and p_value for every network in both atlases
                    for _, net_row in res_df.iterrows():
                        group = net_row['group']
                        name = net_row['name']
                        result_row[f'{group}_{name}_dice'] = f"{net_row['dice']:.4f}"
                        result_row[f'{group}_{name}_p_value'] = f"{net_row['p_value']:.4f}"

                    # Best network overall for each atlas (lowest p_value, then highest dice as tiebreaker)
                    for group in ['EG17', 'TY17']:
                        group_rows = res_df[res_df['group'] == group]
                        if not group_rows.empty:
                            best = group_rows.sort_values(
                                ['p_value', 'dice'],
                                ascending=[True, False]
                            ).iloc[0]
                            result_row[f'{group}_best_network'] = best['name']
                            result_row[f'{group}_best_dice'] = f"{best['dice']:.4f}"
                            result_row[f'{group}_best_p_value'] = f"{best['p_value']:.4f}"

                except Exception as e:
                    print(f"    Warning: Could not parse {csv_file.name}: {e}")
                    continue

            results.append(result_row)

        else:
            print(f"  ✗ NCT analysis failed")
            print(result.stdout)
            print(result.stderr)

            results.append({
                'Subject': subj,
                'Community': comm,
                'Network': row['Network'],
                'FC_Similarity': row['FC_Similarity'],
                'Spatial_Score': row['Spatial_Score'],
                'Confidence': row['Confidence'],
                'Alt_1_Network': row['Alt_1_Network'],
                'NCT_status': 'Error'
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
