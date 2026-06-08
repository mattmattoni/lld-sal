# lld-sal

Precision functional mapping pipeline for the salience network in late-life depression (REMBRANDT), run on an HPC cluster over CIFTI fMRI data.
Code is largely adapted from Lynch et al 2024: https://doi.org/10.1038/s41586-024-07805-2

Additional scripts to validate networks using Network Correspondence Toolbox https://doi.org/10.1038/s41467-025-58176-9

`MSCcodebase-master/`, `cifti-matlab-master/`, `workbench/`, `Infomap`, and `PFM-Tutorial/` are third-party dependencies.

## Data preparation

- `DirOrg.sh` — Renames and cleans subject directories across the three sites (UIC, VUMC, UPMC).
- `ciftify_recon_job.sbatch` — Runs ciftify anatomical reconstruction (FreeSurfer to HCP/CIFTI surface space). Only done for BL. 
- `ciftify_fmri_job.sbatch` — Maps resting-state fMRI runs into CIFTI surface space via ciftify.
- `ciftify_taskfmri_job.sbatch` — Maps the MSIT task fMRI runs into CIFTI surface space via ciftify.
- `DataCheck.sh` — Audits raw, CIFTI, and processed file availability per subject into a summary CSV.
- `MissingData.sh` — Checks which HCP outputs exist per subject and writes the inclusion sublist. Provides argument key for runPFM

## Precision functional mapping

- `PFM_batch.m` — Per-subject PFM: temporal concatenation, infomap community detection, and algorithmic labeling.
- `runPFM.sh` — SLURM launcher that runs `PFM_batch.m` across subjects in parallel.

## Network correspondence toolbox validation and labeling

- `getSalienceCommunities.py` — Collects salience community assignments across all subjects into one CSV.
- `run_getSalienceCommunities.sbatch` — SLURM launcher for `getSalienceCommunities.py`.
- `prepNCT.py` — Prepares salience communities for NCT (extracts matrices and config files).
- `run_prepNCT.sh` — SLURM launcher for `prepNCT.py`.
- `NCT.py` — Runs network control theory analysis per salience community.
- `runNCT.sh` — SLURM launcher for `NCT.py`.
- `nct_validator.py` — Validates network assignments against hierarchical correspondence rules.
- `update_network_labels.py` — Writes manual-decision label files from the validation results.
- `PFM_adjust_networks.m` — Applies manual decisions and recomputes adjusted network assignments and sizes.
- `run_validation_pipeline.sh` — Runs the validator then the label updater in sequence.

## Data extraction

- `getNetworkSizes.sh` — Computes raw and adjusted network sizes per subject.
- `extract_FC.py` — Extracts ACC and insula functional connectivity from parcellated timeseries.
- `run_extract_FC.sbatch` — SLURM launcher for `extract_FC.py`.
- `get_FCestimates.py` — Aggregates per-subject FC matrices into a group-level summary.

## Miscellaneous

- `PFM_singlesub.m` — Single-subject PFM run for testing on one subject.
- `surface_vertex.sbatch` — Computes per-vertex surface areas for each subject.
- `GroupAveraging.sbatch` — Builds group-average network labels by taking the mode across subjects. Currently faulty. 
- `resample_salprior.py` — Converts salience priors from .mat to GIFTI and resamples to fs_LR_32k.
- `priorsCheck.py` — Checks salience prior overlap against reference atlases.
- `BaselineComparison.R` — Merges network sizes with clinical outcomes and runs baseline group comparisons.
- `extractSalAssignments.sbatch` — Extracts salience community labels and confidence scores per subject.



