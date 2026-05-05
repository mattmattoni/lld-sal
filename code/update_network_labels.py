import pandas as pd
import os
from pathlib import Path


def update_network_labels():
    """
    Updates NetworkLabels.xls files with manual decisions for changed networks.
    Creates +ManualDecisions files for ALL subjects.
    """
    
    # File paths
    validated_file = '/home/mattonim/psych_oajilore_chi_link/mattonim/lld-sal/derivatives/validated_assignments.csv'
    pfm_base = '/scratch/network/mattonim/pfm_output'
    
    print("UPDATING NETWORK LABELS WITH MANUAL DECISIONS")
    
    # Load validation results
    print(f"\nLoading validation results...")
    validated_df = pd.read_csv(validated_file)
    
    # Get all unique subjects
    all_subjects = validated_df['Subject'].unique()
    print(f"Total subjects: {len(all_subjects)}")
    
    # Get changed assignments
    changed_df = validated_df[validated_df['Changed'] == True].copy()
    subjects_with_changes = set(changed_df['Subject'].unique())
    print(f"Subjects with changes: {len(subjects_with_changes)}")
    print(f"Subjects with no changes: {len(all_subjects) - len(subjects_with_changes)}")
    
    updated_files = 0
    errors = []
    
    for subject_id in sorted(all_subjects):
        # Format subject ID with leading zeros (e.g., 1 -> 001)
        subject_str = f"{subject_id:03d}"
        
        # Build path to NetworkLabels file
        network_labels_path = os.path.join(
            pfm_base,
            subject_str,
            'pfm',
            'Bipartite_PhysicalCommunities+AlgorithmicLabeling_NetworkLabels.xls'
        )
        
        # Check if file exists
        if not os.path.exists(network_labels_path):
            error_msg = f"Subject {subject_str}: File not found at {network_labels_path}"
            errors.append(error_msg)
            print(f"\n  {error_msg}")
            continue
        
        try:
            # Read the NetworkLabels file
            network_labels_df = pd.read_excel(network_labels_path)
            
            # Verify Network_ManualDecision column exists
            if 'Network_ManualDecision' not in network_labels_df.columns:
                error_msg = f"Subject {subject_str}: Network_ManualDecision column not found in file"
                errors.append(error_msg)
                print(f"\n  {error_msg}")
                continue
            
            # Check if this subject has changes
            if subject_id in subjects_with_changes:
                # Get changes for this subject
                subject_changes = changed_df[changed_df['Subject'] == subject_id]
                
                # Update each changed community
                changes_applied = 0
                for _, change_row in subject_changes.iterrows():
                    community = change_row['Community']
                    new_network = change_row['Final_Network']
                    
                    # Find matching row in network_labels_df
                    mask = network_labels_df['Community'] == community
                    
                    if mask.sum() == 0:
                        error_msg = f"Subject {subject_str}, Community {community}: Not found in labels file"
                        errors.append(error_msg)
                        continue
                    
                    # Update the Network_ManualDecision column
                    network_labels_df.loc[mask, 'Network_ManualDecision'] = new_network
                    changes_applied += 1
                
                print(f"\n  Subject {subject_str}: Updated {changes_applied} communities")
            else:
                # No changes for this subject, but still create the file
                print(f"\n  Subject {subject_str}: No changes")
            
            # Save updated file with new name (for ALL subjects)
            output_path = os.path.join(
                pfm_base,
                subject_str,
                'pfm',
                'Bipartite_PhysicalCommunities+AlgorithmicLabeling_NetworkLabels+ManualDecisions.xls'
            )
            
            network_labels_df.to_excel(output_path, index=False, engine='openpyxl')
            updated_files += 1
            
        except Exception as e:
            error_msg = f"Subject {subject_str}: Error - {str(e)}"
            errors.append(error_msg)
            print(f"\n  {error_msg}")
    
    # Summary
    print("\nSUMMARY")
    print(f"Files successfully updated: {updated_files}")
    print(f"Errors encountered: {len(errors)}")
    
    if errors:
        print("\nErrors:")
        for error in errors:
            print(f"  - {error}")
    
    print("\nDone!")


if __name__ == "__main__":
    update_network_labels()