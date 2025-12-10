import os
os.environ['DISABLE_NCT_AUTO_UPDATE'] = '1'

import cbig_network_correspondence as cnc

config_content = """[data_info]
Data_Name: Salience_Prior
Data_Space: fs_LR_32k
Data_Type: Metric
"""

config_file = '/scratch/network/mattonim/sphere_files/salience_config.txt'
with open(config_file, 'w') as f:
    f.write(config_content)

# USE THE FIXED FILE
salience_file = '/scratch/network/mattonim/sphere_files/salience_32k_full_FIXED.mat'
ref_params = cnc.compute_overlap_with_atlases.DataParams(config_file, salience_file)

atlas_names = ["XS268_8", "TY7", "TY17", "EG17"]
output_dir = '/scratch/network/mattonim/salience_nct_results_FIXED'

print("Running with FIXED data...")
cnc.compute_overlap_with_atlases.network_correspondence(
    ref_params, 
    atlas_names,
    output_dir
)

print(f"\nResults saved to: {output_dir}")