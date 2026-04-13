#!/bin/bash
#SBATCH --job-name=prep_nct
#SBATCH --output=/projects/psych_oajilore_chi/mattonim/lld-sal/logs/nct_%j.log
#SBATCH --error=/projects/psych_oajilore_chi/mattonim/lld-sal/logs/nct_%j.err
#SBATCH --nodes=1
#SBATCH --ntasks=2
#SBATCH --cpus-per-task=6
#SBATCH --mem=240G
#SBATCH --time=1:00:00
#SBATCH --partition=batch

module load python3
pip install --user nibabel scipy

python3 prepNCT.py