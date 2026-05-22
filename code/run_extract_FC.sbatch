#!/bin/bash
#SBATCH --job-name=extract_FC
#SBATCH --output=/projects/psych_oajilore_chi/mattonim/lld-sal/logs/extract_FC_%j.log
#SBATCH --time=08:00:00
#SBATCH --mem=32G
#SBATCH --cpus-per-task=1
#SBATCH --partition=batch

module load python3

python3 extract_FC.py
