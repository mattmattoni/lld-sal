import cbig_network_correspondence as cnc

# Create config file for your salience priors
config_content = """[data_info]
Data_Name: Salience_Prior
Data_Space: fs_LR_32k
Data_Type: Metric
Data_Threshold: [0.5,Inf]
"""

# Save config file
config_file = '/scratch/network/mattonim/sphere_files/salience_config.txt'
with open(config_file, 'w') as f:
    f.write(config_content)

# Path to your salience CIFTI file
salience_file = '/scratch/network/mattonim/sphere_files/salience_prior_32k.dtseries.nii'

# Create DataParams object
ref_params = cnc.compute_overlap_with_atlases.DataParams(config_file, salience_file)

# Choose atlases to compare against (all in fs_LR_32k space)
atlas_names = [
    "EG17",        # Evan Gordon 17 networks
    "TY7",         # Thomas Yeo 7 networks  
    "TY17",        # Thomas Yeo 17 networks
    "AS400Y17",    # Schaefer 400-ROI with Yeo 17 networks
    "MG360J12",    # Glasser 360-ROI with Ji 12 networks
    "AS200Y17",    # Schaefer 200-ROI with Yeo 17 networks
]

# Output directory
output_dir = '/scratch/network/mattonim/salience_nct_results'

# Run the network correspondence analysis
print("Running network correspondence analysis...")
cnc.compute_overlap_with_atlases.network_correspondence(
    ref_params, 
    atlas_names,
    output_dir
)
