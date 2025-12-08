#!/bin/bash
#SBATCH --job-name=prep_nct
#SBATCH --output=/projects/psych_oajilore_chi/mattonim/lld-sal/logs/prep_nct_%j.log
#SBATCH --time=02:00:00
#SBATCH --mem=4G
#SBATCH --partition=batch

module load python3
pip install --user nibabel scipy

python3 prepNCT.py