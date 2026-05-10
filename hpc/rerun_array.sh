#!/bin/bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
build_dir="${BUILD_DIR:-$repo_root/HHASARL}"
collection_dir="${COLLECTION_DIR:-$build_dir/EVRP/evrp-benchmark-set/Complete}"
log_dir="${LOG_DIR:-$repo_root/logs}"
job_name="${JOB_NAME:-hhasarl-rerun}"
sbatch_script="$repo_root/hpc/run_instance_array.sbatch"
failed_file="${FAILED_INSTANCES_FILE:-$repo_root/hpc/failed_instances.txt}"

if [[ ! -f "$failed_file" ]]; then
    echo "Failed instance file does not exist: $failed_file" >&2
    exit 1
fi

mapfile -t cases < "$failed_file"
filtered_cases=()
for case_name in "${cases[@]}"; do
    case_name="${case_name#"${case_name%%[![:space:]]*}"}"
    case_name="${case_name%"${case_name##*[![:space:]]}"}"
    [[ -z "$case_name" || "${case_name:0:1}" == "#" ]] && continue
    filtered_cases+=("$case_name")
done

if (( ${#filtered_cases[@]} == 0 )); then
    echo "No failed instances found in $failed_file" >&2
    exit 1
fi

mkdir -p "$log_dir"

export HHASARL_FAILED_INSTANCES="$(realpath "$failed_file")"
export HHASARL_COLLECTION_DIR="${HHASARL_COLLECTION_DIR:-$collection_dir}"

echo "Array index mapping for failed instances:"
for i in "${!filtered_cases[@]}"; do
    echo "  Task $i -> ${filtered_cases[$i]}"
done

sbatch \
    --array="0-$(( ${#filtered_cases[@]} - 1 ))%4" \
    --job-name="$job_name" \
    --output="$log_dir/%x-%A_%a.out" \
    --chdir="$build_dir" \
    "$sbatch_script"

echo "Submitted rerun job array for ${#filtered_cases[@]} failed instances."
