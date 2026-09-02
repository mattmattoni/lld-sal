#!/usr/bin/env python3

import os
import nibabel as nib
import numpy as np
import pandas as pd
from scipy.stats import pearsonr
import matplotlib.pyplot as plt
import seaborn as sns
from datetime import datetime

SUBJECT_LIST = '/home/mattonim/psych_oajilore_chi_link/mattonim/lld-sal/logs/sublist_include.txt'
PFM_BASE_DIR = '/scratch/network/mattonim/pfm_output'
PARCELLATION_PATH = '/home/mattonim/psych_oajilore_chi_link/mattonim/rembrandt/data_hcp/SUBJECT/MNINonLinear/fsaverage_LR32k/SUBJECT.aparc.32k_fs_LR.dlabel.nii'
OUTPUT_BASE_DIR = '/scratch/network/mattonim/pfm_output/connectivity_results_month16'
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
    data['labels_cifti'] = nib.load(label_file)
    data['network_labels'] = data['labels_cifti'].get_fdata()[0, :]
    
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


def extract_networks(ts_data, net_labels, labels_cifti):
    # Get label table from dlabel file
    named_maps = list(labels_cifti.header.get_index_map(0).named_maps)
    label_table = named_maps[0].label_table
    
    # Build network ID to name mapping
    net_id_to_name = {}
    for key in label_table.keys():
        if key > 0:  # Skip 0 (background/unknown)
            net_id_to_name[int(key)] = label_table[key].label
    
    # Extract timeseries for each network
    networks = {}
    for net_id in np.unique(net_labels[net_labels > 0]):
        net_id = int(net_id)
        network_name = net_id_to_name.get(net_id, f"Network_{net_id}")
        
        if network_name == "Noise":
            continue
        
        mask = net_labels == net_id
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


def compute_net_fc(networks):
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
    pfm_dir = os.path.join(PFM_BASE_DIR, subject_id, 'pfm-16')
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
        
        networks = extract_networks(data['ts_data'], data['network_labels'], data['labels_cifti'])
        
        comp_fc, comp_names = compute_fc(structures, networks)
        net_fc, net_names = compute_net_fc(networks)
        
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