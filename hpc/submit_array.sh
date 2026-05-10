#!/bin/bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
build_dir="${BUILD_DIR:-$repo_root/HHASARL}"
collection_dir="${COLLECTION_DIR:-$build_dir/EVRP/evrp-benchmark-set/Complete}"
log_dir="${LOG_DIR:-$repo_root/logs}"
job_name="${JOB_NAME:-hhasarl}"
sbatch_script="$repo_root/hpc/run_instance_array.sbatch"

instance_count=$(find "$collection_dir" -maxdepth 1 -type f -name '*.txt' | wc -l | tr -d ' ')
if [[ "$instance_count" -eq 0 ]]; then
    echo "No .txt instances found in $collection_dir" >&2
    exit 1
fi

array_max=$((instance_count - 1))
mkdir -p "$log_dir"

export HHASARL_COLLECTION_DIR="${HHASARL_COLLECTION_DIR:-$collection_dir}"

sbatch \
    --array="0-$array_max%8" \
    --job-name="$job_name" \
    --output="$log_dir/%x-%A_%a.out" \
    --chdir="$build_dir" \
    "$sbatch_script"
