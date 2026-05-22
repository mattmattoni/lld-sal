#!/usr/bin/env python3

import os
import nibabel as nib
import numpy as np
import pandas as pd
from scipy.stats import pearsonr
import matplotlib.pyplot as plt
import seaborn as sns
from datetime import datetime

# Edit these paths
SUBJECT_LIST = '/home/mattonim/psych_oajilore_chi_link/mattonim/lld-sal/logs/sublist_include.txt'
PFM_BASE_DIR = '/scratch/network/mattonim/pfm_output'
PARCELLATION_PATH = '/home/mattonim/psych_oajilore_chi_link/mattonim/rembrandt/data_hcp/SUBJECT/MNINonLinear/fsaverage_LR32k/SUBJECT.aparc.32k_fs_LR.dlabel.nii'
OUTPUT_BASE_DIR = '/scratch/network/mattonim/pfm_output/connectivity_results'
NO_PLOTS = False

# Desikan-Killiany parcel IDs
DK_ACC = {'L_caudalanteriorcingulate': 1002, 'L_rostralanteriorcingulate': 1026,
          'R_caudalanteriorcingulate': 2002, 'R_rostralanteriorcingulate': 2026}
DK_INS = {'L_insula': 1035, 'R_insula': 2035}


def load_data(pfm_dir, subject_id, parc_file):
    data = {}
    ts_file = os.path.join(pfm_dir, f'sub-{subject_id}_concatenated_32k_fsLR.dtseries.nii')
    data['ts_cifti'] = nib.load(ts_file)
    data['ts_data'] = data['ts_cifti'].get_fdata()
    
    label_file = os.path.join(pfm_dir, 'Bipartite_PhysicalCommunities+AlgorithmicLabeling_adjusted.dlabel.nii')
    data['network_labels'] = nib.load(label_file).get_fdata()[0, :]
    
    net_fc = os.path.join(pfm_dir, 'Bipartite_PhysicalCommunities+AlgorithmicLabeling_FC_btwn_InfoMapCommunities.dtseries.nii')
    data['net_fc'] = nib.load(net_fc).get_fdata() if os.path.exists(net_fc) else None
    
    csv_file = os.path.join(pfm_dir, 'Bipartite_PhysicalCommunities+AlgorithmicLabeling_NetworkLabels+ManualDecisions.csv')
    data['net_names'] = pd.read_csv(csv_file) if os.path.exists(csv_file) else None
    
    data['parc_labels'] = nib.load(parc_file).get_fdata()[0, :]
    return data


def extract_structures(cifti_file, ts_data):
    structures = {}
    current_idx = 0
    for bm in cifti_file.header.get_index_map(1).brain_models:
        n = bm.index_count
        structures[bm.brain_structure] = {'ts': np.mean(ts_data[:, current_idx:current_idx + n], axis=1)}
        current_idx += n
    return structures


def extract_roi(ts_data, parc_labels, parcel_dict):
    mask = np.zeros(len(parc_labels), dtype=bool)
    for pid in parcel_dict.values():
        mask |= (parc_labels == pid)
    return {'ts': np.mean(ts_data[:, mask], axis=1)} if np.sum(mask) > 0 else None


def extract_networks(ts_data, net_labels, net_names_df):
    # Build community ID to network name mapping
    comm_to_network = {}
    if net_names_df is not None:
        for _, row in net_names_df.iterrows():
            comm_id = int(row.iloc[0])
            manual = row.iloc[2] if len(row) > 2 else None
            auto = row.iloc[1] if len(row) > 1 else None
            
            if manual and pd.notna(manual) and str(manual).strip():
                network_name = str(manual).strip()
            elif auto and pd.notna(auto):
                network_name = str(auto).strip()
            else:
                network_name = f"Network_{comm_id}"
            
            comm_to_network[comm_id] = network_name
    
    # Group communities by network name
    network_masks = {}
    for comm_id in np.unique(net_labels[net_labels > 0]):
        comm_id = int(comm_id)
        network_name = comm_to_network.get(comm_id, f"Network_{comm_id}")
        
        comm_mask = net_labels == comm_id
        if network_name in network_masks:
            network_masks[network_name] |= comm_mask
        else:
            network_masks[network_name] = comm_mask
    
    # Compute mean timeseries per network
    networks = {}
    for network_name, mask in network_masks.items():
        ts = np.mean(ts_data[:, mask], axis=1)
        networks[network_name] = {'ts': ts}
    
    return networks


def compute_fc(rois, networks):
    names = []
    timeseries = []
    
    for name in sorted([k for k in rois.keys() if 'CORTEX' not in k]):
        names.append(name)
        timeseries.append(rois[name]['ts'])
    
    for network_name in sorted(networks.keys()):
        names.append(network_name)
        timeseries.append(networks[network_name]['ts'])
    
    n = len(names)
    fc = np.zeros((n, n))
    for i in range(n):
        for j in range(n):
            fc[i, j] = 1.0 if i == j else pearsonr(timeseries[i], timeseries[j])[0]
    
    return fc, names


def compute_net_fc(networks, precomputed):
    names = sorted(networks.keys())
    n = len(names)
    
    fc = np.zeros((n, n))
    for i, name1 in enumerate(names):
        for j, name2 in enumerate(names):
            fc[i, j] = 1.0 if i == j else pearsonr(networks[name1]['ts'], networks[name2]['ts'])[0]
    
    return fc, names


def save_results(output_dir, subject_id, comp_fc, comp_names, net_fc, net_names, no_plots):
    os.makedirs(output_dir, exist_ok=True)
    
    comp_file = os.path.join(output_dir, f'{subject_id}_Comprehensive_FC.csv')
    pd.DataFrame(comp_fc, index=comp_names, columns=comp_names).to_csv(comp_file)
    
    net_file = os.path.join(output_dir, f'{subject_id}_Network-Network_FC.csv')
    pd.DataFrame(net_fc, index=net_names, columns=net_names).to_csv(net_file)
    
    if not no_plots:
        sns.set_style("white")
        
        fig, ax = plt.subplots(figsize=(16, 14))
        sns.heatmap(comp_fc, xticklabels=comp_names, yticklabels=comp_names,
                   cmap='RdBu_r', center=0, vmin=-1, vmax=1, square=True,
                   cbar_kws={'label': 'Pearson r'}, ax=ax)
        plt.title(f'{subject_id}: Comprehensive FC', fontsize=14, fontweight='bold')
        plt.xticks(rotation=45, ha='right')
        plt.tight_layout()
        plt.savefig(comp_file.replace('.csv', '.png'), dpi=300, bbox_inches='tight')
        plt.close()
        
        fig, ax = plt.subplots(figsize=(12, 10))
        sns.heatmap(net_fc, xticklabels=net_names, yticklabels=net_names,
                   cmap='RdBu_r', center=0, vmin=-1, vmax=1, square=True,
                   cbar_kws={'label': 'Pearson r'}, ax=ax)
        plt.title(f'{subject_id}: Network-Network FC', fontsize=14, fontweight='bold')
        plt.xticks(rotation=45, ha='right')
        plt.tight_layout()
        plt.savefig(net_file.replace('.csv', '.png'), dpi=300, bbox_inches='tight')
        plt.close()


def process_subject(subject_id):
    pfm_dir = os.path.join(PFM_BASE_DIR, subject_id, 'pfm')
    parc_file = PARCELLATION_PATH.replace('SUBJECT', subject_id)
    
    if not os.path.exists(pfm_dir):
        return False, "PFM dir not found"
    if not os.path.exists(parc_file):
        return False, "Parcellation not found"
    
    try:
        data = load_data(pfm_dir, subject_id, parc_file)
        
        structures = extract_structures(data['ts_cifti'], data['ts_data'])
        acc = extract_roi(data['ts_data'], data['parc_labels'], DK_ACC)
        insula = extract_roi(data['ts_data'], data['parc_labels'], DK_INS)
        
        if acc:
            structures['ACC'] = acc
        if insula:
            structures['insula'] = insula
        
        networks = extract_networks(data['ts_data'], data['network_labels'], data['net_names'])
        
        comp_fc, comp_names = compute_fc(structures, networks)
        net_fc, net_names = compute_net_fc(networks, data['net_fc'])
        
        output_dir = OUTPUT_BASE_DIR if OUTPUT_BASE_DIR else os.path.join(pfm_dir, '../connectivity_analysis')
        
        save_results(output_dir, f'sub-{subject_id}', comp_fc, comp_names, net_fc, net_names, NO_PLOTS)
        
        return True, "Success"
    except Exception as e:
        return False, str(e)[:50]


def main():
    with open(SUBJECT_LIST, 'r') as f:
        subjects = [line.strip() for line in f if line.strip() and not line.startswith('#')]
    
    print(f"\nProcessing {len(subjects)} subjects")
    print(f"Started: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
    
    results = []
    for i, subject in enumerate(subjects, 1):
        print(f"[{i}/{len(subjects)}] {subject}...", end=' ', flush=True)
        success, msg = process_subject(subject)
        results.append((subject, success))
        print("✓" if success else f"✗ {msg}")
    
    n_success = sum(1 for _, s in results if s)
    print(f"\nComplete: {n_success}/{len(subjects)} succeeded")
    
    if n_success < len(subjects):
        print("\nFailed:")
        for subj, success in results:
            if not success:
                print(f"  {subj}")


if __name__ == '__main__':
    main()