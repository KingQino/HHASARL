# HHASARL

This is a MATLAB project for solving Electric Vehicle Routing Problem instances (EVRP/CEVRP). The core HHASARL search logic has been kept unchanged. The main updates in this repository are experimental I/O cleanup, logging, and a revised evaluation-budget accounting method for easier local and HPC experimentation.

## Source

```bibtex
@article{rodriguez2024new,
  title={A new hyper-heuristic based on adaptive simulated annealing and reinforcement learning for the capacitated electric vehicle routing problem},
  author={Rodr{\'\i}guez-Esparza, Erick and Masegosa, Antonio D and Oliva, Diego and Onieva, Enrique},
  journal={Expert Systems with Applications},
  volume={252},
  pages={124197},
  year={2024},
  publisher={Elsevier}
}
```

## Repository Layout

- `HHASARL/`: main MATLAB source directory
- `HHASARL/EVRP/evrp-benchmark-set/Complete/`: instance collection used by the current experiments, stored as `.txt`
- `HHASARL/stats/`: experiment output directory
- `hpc/`: Slurm/HPC helper scripts

## How To Run

### 1. Run all instances locally

The default entry point is `HHASARL/Main.m`. It scans `HHASARL/EVRP/evrp-benchmark-set/Complete/*.txt` in filename order and runs each instance `10` times using fixed random seeds `1..10`.

In MATLAB:

1. Enter the `HHASARL/` code directory.
2. Adjust the parameters in `Main.m` if needed:
   - `RL = 2`
     - `0`: Rand
     - `1`: Epsilon-greedy
     - `2`: Thompson Sampling
     - `3`: UCB1
   - `print = 0`
     - `1` prints per-iteration logs to MATLAB or Slurm stdout
   - `draw = 0`
     - `1` enables plotting
   - `MAX_TRIALS = 10`
3. Run `Main`

### 2. Run a single instance locally

The recommended entry point is `RunInstanceExperiment.m`:

```matlab
cd('HHASARL');
RunInstanceExperiment( ...
    'EVRP/evrp-benchmark-set/Complete/E-n22-k4.txt', ...
    2, ...   % RL
    0, ...   % print
    0, ...   % draw
    10, ...  % number of seeds / trials
    1, ...   % number of workers
    'stats', ...
    'HHASARL');
```

If `print` is set to `1`, iteration logs are written to the MATLAB console. On HPC, the same logs go to the Slurm stdout file.

### 3. Run on HPC / Slurm

The repository includes array-job scripts:

- `hpc/run_instance_array.sbatch`
- `hpc/submit_array.sh`

A typical submission flow is:

```bash
BUILD_DIR=/path/to/HHASARL/HHASARL \
COLLECTION_DIR=/path/to/HHASARL/HHASARL/EVRP/evrp-benchmark-set/Complete \
LOG_DIR=/path/to/logs \
JOB_NAME=hhasarl \
HHASARL_STATS_ROOT=/path/to/stats \
HHASARL_MAX_TRIALS=10 \
bash hpc/submit_array.sh
```

## Output Format

For instance `E-n22-k4.txt`, the output looks like:

```text
stats/HHASARL/E-n22-k4/
  stats.E-n22-k4.txt
  1/
    solution.E-n22-k4.txt
    evols.E-n22-k4.csv
  2/
  ...
  10/
```

## Core Modifications

### 1. The algorithmic logic is unchanged

This repository does not change the core HHASARL search logic, neighborhood set, reinforcement learning strategy, or simulated annealing acceptance rule. In other words, the search behavior is still the original HHASARL algorithm.

### 2. Evaluation-budget accounting now follows a WCCI2020 EVRP benchmark official scheme

The original MATLAB version used a coarse `evals` counter. Many operations were not charged explicitly. This repository replaces that with a finer-grained unified counter:

- one full solution evaluation: `+1 eval`
- one distance access: `+ 1 / ACTUAL_PROBLEM_SIZE`
- solution transformations, repairs, station checks, and feasibility checks also accumulate partial evaluations

As a result, the `evals` values in this repository are no longer directly comparable to the original MATLAB version. They are now much closer to the accounting style used in VNS-EVRP-2020. Because partial evaluations accumulate during the search flow, the final `evals` value may slightly exceed the nominal budget, which is expected.

### 3. Logs and experiment records were standardized

- standardized `stats / solution / evols` outputs were added
- `print=1` now exposes per-iteration logs
- repeated runs are stored by random seed in separate subdirectories for easier post-processing and comparison

### 4. Instance parsing is now section-based

`Model.m` now reads instances by parsing the relevant sections instead of relying on the unreliable `DIMENSION` field:

- `NODE_COORD_SECTION`
- `DEMAND_SECTION`
- `STATIONS_COORD_SECTION`
- `DEPOT_SECTION`

The total problem size is computed as:

```text
ACTUAL_PROBLEM_SIZE = STATIONS + number_of_customers + number_of_depots
```

