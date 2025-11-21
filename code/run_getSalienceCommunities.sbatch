#!/bin/bash
#SBATCH --job-name=extract_salience
#SBATCH --output=/projects/psych_oajilore_chi/mattonim/lld-sal/logs/extract_salience_%j.log
#SBATCH --time=01:00:00
#SBATCH --mem=4G
#SBATCH --cpus-per-task=1
#SBATCH --partition=batch

module load python3

python3 extract_salience_communities.py
