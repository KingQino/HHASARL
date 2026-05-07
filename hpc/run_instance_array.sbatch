#!/bin/bash
#SBATCH --partition=compute
#SBATCH --job-name=hhasarl
#SBATCH --output=logs/%x-%A_%a.out
#SBATCH --time=48:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu=4G

set -euo pipefail

# Adjust this line to match your cluster environment.
module purge
module load matlab/2024a

# Avoid nested BLAS/OpenMP threading when parfor workers are already used.
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export MATLAB_USE_DISPLAY=0

export HHASARL_COLLECTION_DIR="${HHASARL_COLLECTION_DIR:-EVRP/evrp-benchmark-set/Complete}"
export HHASARL_STATS_ROOT="${HHASARL_STATS_ROOT:-stats}"
export HHASARL_ALGORITHM_NAME="${HHASARL_ALGORITHM_NAME:-HHASARL}"
export HHASARL_MAX_TRIALS="${HHASARL_MAX_TRIALS:-10}"
export HHASARL_RL="${HHASARL_RL:-2}"
export HHASARL_PRINT="${HHASARL_PRINT:-0}"
export HHASARL_DRAW="${HHASARL_DRAW:-0}"

matlab -nodisplay -nosplash -nodesktop -batch "RunInstanceHPC"
