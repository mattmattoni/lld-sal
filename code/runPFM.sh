#!/bin/bash
#SBATCH --job-name=pfm_single
#SBATCH --partition=batch
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=6
#SBATCH --mem=128G
#SBATCH --time=4:00:00
#SBATCH --output=/home/mattonim/psych_oajilore_chi_link/mattonim/lld-sal/logs/pfm_%j.log
#SBATCH --error=/home/mattonim/psych_oajilore_chi_link/mattonim/lld-sal/logs/pfm_%j.err

# Set up environment
WB=/home/mattonim/workbench
export LD_LIBRARY_PATH=$WB/libs_linux64:$LD_LIBRARY_PATH
module load matlab/2024b

MATLAB_SCRIPT=/home/mattonim/psych_oajilore_chi_link/mattonim/lld-sal/code/PFM_singlesub.m

matlab -nodisplay -nosplash -r "try, run('$MATLAB_SCRIPT'); catch ME, disp(ME.message); end; exit"
