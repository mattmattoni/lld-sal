import pandas as pd
import numpy as np
from typing import Tuple, Dict


class NCTValidator:
    """Validates network assignments based on hierarchical rules."""
    
    # Mapping from full network names to EG17 abbreviated names
    NETWORK_TO_EG17 = {
        'Auditory': 'Auditory',
        'CinguloOpercular/Action-mode': 'CingOperc',
        'Default_Anterolateral': 'AntMTL',           # Anterior MTL
        'Default_Dorsolateral': 'Context',           # Context/Dorsolateral
        'Default_Parietal': 'ParMemory',             # Parietal Memory
        'Default_Retrosplenial': 'PostMTL',          # Posterior MTL
        'DorsalAttention': 'DorsAttn',
        'Frontoparietal': 'FrontPar',
        'Language': 'Language',
        'MedialParietal': 'Default',                 # Core Default
        'Salience': 'Salience',
        'SomatoCognitiveAction': 'Premotor',
        'Somatomotor_Face': 'FaceSM',
        'Somatomotor_Foot': 'FootSM',
        'Somatomotor_Hand': 'HandSM',
        'Visual_Dorsal/VentralStream': 'DorsAttn',
        'Visual_Lateral': 'LatVis',
        'Visual_V1': 'MedVis'
    }
    
    # Reverse mapping: EG17 names back to original names
    EG17_TO_NETWORK = {
        'Auditory': 'Auditory',
        'CingOperc': 'CinguloOpercular/Action-mode',
        'Default': 'MedialParietal',
        'PostMTL': 'Default_Retrosplenial',
        'DorsAttn': 'DorsalAttention',
        'FrontPar': 'Frontoparietal',
        'Language': 'Language',
        'Salience': 'Salience',
        'Premotor': 'SomatoCognitiveAction',
        'FaceSM': 'Somatomotor_Face',
        'FootSM': 'Somatomotor_Foot',
        'HandSM': 'Somatomotor_Hand',
        'LatVis': 'Visual_Lateral',
        'MedVis': 'Visual_V1',
        'AntMTL': 'Default_Anterolateral',
        'Context': 'Default_Dorsolateral',
        'ParMemory': 'Default_Parietal'
    }
    
    def __init__(self, 
                 confidence_threshold: float = 0.40,
                 fc_threshold_1: float = 0.10,
                 fc_threshold_2: float = 0.15,
                 fc_threshold_3: float = 0.10,
                 p_threshold: float = 0.05):
        self.confidence_threshold = confidence_threshold
        self.fc_threshold_1 = fc_threshold_1
        self.fc_threshold_2 = fc_threshold_2
        self.fc_threshold_3 = fc_threshold_3
        self.p_threshold = p_threshold
    
    def extract_eg17_networks(self, row: pd.Series) -> Dict[str, Tuple[float, float]]:
        eg17_networks = {}
        for col in row.index:
            if col.startswith('EG17_') and col.endswith('_dice'):
                network_name = col.replace('_dice', '')
                p_col = f'{network_name}_p_value'
                if p_col in row.index:
                    dice = row[col]
                    p_val = row[p_col]
                    if pd.notna(dice) and pd.notna(p_val):
                        eg17_networks[network_name] = (dice, p_val)
        return eg17_networks
    
    def get_primary_p(self, row: pd.Series) -> float:
        primary_network = row['Network']
        eg17_name = self.NETWORK_TO_EG17.get(primary_network, primary_network)
        p_col = f'EG17_{eg17_name}_p_value'
        if p_col in row.index:
            return row[p_col]
        return np.nan
    
    def get_secondary_p(self, row: pd.Series) -> Tuple[float, float]:
        if pd.isna(row['Alt_1_Network']):
            return np.nan, np.nan
        
        secondary_network = row['Alt_1_Network']
        secondary_fc = row.get('Alt_1_FC_Similarity', np.nan)
        eg17_name = self.NETWORK_TO_EG17.get(secondary_network, secondary_network)
        p_col = f'EG17_{eg17_name}_p_value'
        
        if p_col in row.index:
            return secondary_fc, row[p_col]
        
        return secondary_fc, np.nan
    
    def find_lowest_p_network(self, eg17_networks: Dict[str, Tuple[float, float]]) -> Tuple[str, float]:
        if not eg17_networks:
            return None, np.nan
        min_network = min(eg17_networks.items(), key=lambda x: x[1][1])
        eg17_name = min_network[0].replace('EG17_', '')  # e.g., "DorsAttn"
        original_name = self.EG17_TO_NETWORK.get(eg17_name, eg17_name)  # Convert back to "DorsalAttention"
        return original_name, min_network[1][1]
    
    def validate_assignment(self, row: pd.Series) -> Tuple[str, str, Dict]:
        primary_network = row['Network']
        primary_fc = row['FC_Similarity']
        confidence = row['Confidence']
        primary_p = self.get_primary_p(row)
        secondary_fc, secondary_p = self.get_secondary_p(row)
        secondary_network = row.get('Alt_1_Network')
        eg17_networks = self.extract_eg17_networks(row)
        
        metadata = {
            'original_network': primary_network,
            'primary_fc': primary_fc,
            'primary_p': primary_p,
            'secondary_network': secondary_network,
            'secondary_fc': secondary_fc,
            'secondary_p': secondary_p,
            'confidence': confidence,
            'spatial_score': row['Spatial_Score']
        }
        
        if pd.notna(confidence) and confidence > self.confidence_threshold:
            metadata['lowest_p_network'], metadata['lowest_p_value'] = self.find_lowest_p_network(eg17_networks)
            return primary_network, 'Rule 0: Confidence > 0.40', metadata
        
        if (pd.notna(primary_fc) and primary_fc > self.fc_threshold_1 and
            pd.notna(primary_p) and primary_p < self.p_threshold):
            metadata['lowest_p_network'], metadata['lowest_p_value'] = self.find_lowest_p_network(eg17_networks)
            return primary_network, 'Rule 1: Primary FC > 0.10 AND p < 0.05', metadata
        
        if pd.notna(primary_fc) and primary_fc > self.fc_threshold_2:
            metadata['lowest_p_network'], metadata['lowest_p_value'] = self.find_lowest_p_network(eg17_networks)
            return primary_network, 'Rule 2: Primary FC > 0.15', metadata
        
        if (pd.notna(secondary_fc) and secondary_fc > self.fc_threshold_3 and
            pd.notna(secondary_p) and secondary_p < self.p_threshold):
            metadata['lowest_p_network'], metadata['lowest_p_value'] = self.find_lowest_p_network(eg17_networks)
            return secondary_network, 'Rule 3: Secondary FC > 0.10 AND p < 0.05', metadata
        
        if pd.notna(primary_p) and primary_p < self.p_threshold:
            metadata['lowest_p_network'], metadata['lowest_p_value'] = self.find_lowest_p_network(eg17_networks)
            return primary_network, 'Rule 4: Primary p < 0.05', metadata
        
        if pd.notna(secondary_p) and secondary_p < self.p_threshold:
            metadata['lowest_p_network'], metadata['lowest_p_value'] = self.find_lowest_p_network(eg17_networks)
            return secondary_network, 'Rule 5: Secondary p < 0.05', metadata
        
        lowest_p_net, lowest_p = self.find_lowest_p_network(eg17_networks)
        metadata['lowest_p_network'] = lowest_p_net
        metadata['lowest_p_value'] = lowest_p
        
        if lowest_p_net is not None and pd.notna(lowest_p) and lowest_p < self.p_threshold:
            return lowest_p_net, 'Rule 6: Lowest EG17 p-value', metadata
        
        return primary_network, 'Rule 7: Keep original (fallback)', metadata
    
    def validate_batch(self, df: pd.DataFrame) -> pd.DataFrame:
        results = []
        
        for idx, row in df.iterrows():
            final_network, decision_rule, metadata = self.validate_assignment(row)
            
            result = {
                'Subject': row['Subject'],
                'Community': row['Community'],
                'Original_Network': row['Network'],
                'Final_Network': final_network,
                'Changed': final_network != row['Network'],
                'Decision_Rule': decision_rule,
                'Confidence': metadata['confidence'],
                'Primary_FC': metadata['primary_fc'],
                'Primary_P': metadata['primary_p'],
                'Secondary_Network': metadata['secondary_network'],
                'Secondary_FC': metadata['secondary_fc'],
                'Secondary_P': metadata['secondary_p'],
                'Lowest_P_Network': metadata.get('lowest_p_network'),
                'Lowest_P_Value': metadata.get('lowest_p_value'),
                'Spatial_Score': metadata['spatial_score']
            }
            
            results.append(result)
        
        return pd.DataFrame(results)
    
    def get_summary(self, results_df: pd.DataFrame) -> Dict:
        total = len(results_df)
        rule_counts = results_df['Decision_Rule'].value_counts().to_dict()
        
        return {
            'total_assignments': total,
            'total_changed': results_df['Changed'].sum(),
            'pct_changed': 100 * results_df['Changed'].sum() / total if total > 0 else 0,
            'rule_counts': rule_counts,
            'mean_primary_fc': results_df['Primary_FC'].mean(),
            'mean_primary_p': results_df['Primary_P'].mean(),
            'mean_secondary_fc': results_df['Secondary_FC'].mean(),
            'mean_secondary_p': results_df['Secondary_P'].mean(),
            'mean_confidence': results_df['Confidence'].mean(),
            'mean_spatial_score': results_df['Spatial_Score'].mean()
        }


def main():
    nct_file = '/home/mattonim/psych_oajilore_chi_link/mattonim/lld-sal/derivatives/salience_communities_NCT_results.csv'
    communities_file = '/home/mattonim/psych_oajilore_chi_link/mattonim/lld-sal/derivatives/salience_communities.csv'
    output_file = '/home/mattonim/psych_oajilore_chi_link/mattonim/lld-sal/derivatives/validated_assignments.csv'
    summary_file = '/home/mattonim/psych_oajilore_chi_link/mattonim/lld-sal/derivatives/validation_summary.txt'
    
    nct_df = pd.read_csv(nct_file)
    comm_df = pd.read_csv(communities_file)
    
    merged_df = nct_df.merge(
        comm_df[['Subject', 'Community', 'Alt_1_FC_Similarity']],
        on=['Subject', 'Community'],
        how='left'
    )
    
    validator = NCTValidator()
    results = validator.validate_batch(merged_df)
    summary = validator.get_summary(results)
    
    print(f"Total: {summary['total_assignments']}")
    print(f"Changed: {summary['total_changed']} ({summary['pct_changed']:.1f}%)")
    
    print("\nRules:")
    for rule, count in sorted(summary['rule_counts'].items()):
        pct = 100 * count / summary['total_assignments']
        print(f"  {rule}: {count} ({pct:.1f}%)")
    
    print(f"\nMean FC: {summary['mean_primary_fc']:.3f}")
    print(f"Mean p: {summary['mean_primary_p']:.3f}")
    
    results.to_csv(output_file, index=False)
    
    with open(summary_file, 'w') as f:
        f.write(f"Total: {summary['total_assignments']}\n")
        f.write(f"Changed: {summary['total_changed']} ({summary['pct_changed']:.1f}%)\n\n")
        f.write("Rules Applied:\n")
        for rule, count in sorted(summary['rule_counts'].items()):
            pct = 100 * count / summary['total_assignments']
            f.write(f"  {rule}: {count} ({pct:.1f}%)\n")
        f.write(f"\nMean Primary FC: {summary['mean_primary_fc']:.3f}\n")
        f.write(f"Mean Primary p: {summary['mean_primary_p']:.3f}\n")
    
    print(f"\nSaved: {output_file}")
    print(f"Saved: {summary_file}")
    
    return results, summary


if __name__ == "__main__":
    results, summary = main()