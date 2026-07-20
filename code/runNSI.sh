#!/bin/bash
#SBATCH --job-name=pfm_nsi
#SBATCH --output=/projects/psych_oajilore_chi/mattonim/lld-sal/logs/nsi_%j.log
#SBATCH --error=/projects/psych_oajilore_chi/mattonim/lld-sal/logs/nsi_%j.err
#SBATCH --nodes=1
#SBATCH --ntasks=2
#SBATCH --cpus-per-task=6
#SBATCH --mem=240G
#SBATCH --time=24:00:00
#SBATCH --partition=batch

export PATH=$HOME/.local/bin:$PATH
which pfm-nsi

bash pfm_nsi.sh