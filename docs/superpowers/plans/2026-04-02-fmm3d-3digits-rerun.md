# FMM3D 3-Digit Rerun Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the FMM3D benchmark reusable for different accuracy targets, then submit a Genoa cluster job that regenerates FMM3D results at `eps=1e-3` into a new dataset directory.

**Architecture:** Parameterize the Julia benchmark entrypoint so the epsilon value is passed on the command line, then add a small SLURM wrapper that runs the existing thread-count sweep into `fmm3d/data/96_cores_3digits/`. Keep existing data and plots unchanged.

**Tech Stack:** Julia, FMM3D.jl, SLURM, bash

---

### Task 1: Parameterize The Benchmark Driver

**Files:**
- Modify: `fmm3d/benchmark.jl`

- [ ] **Step 1: Update the benchmark function signature**

```julia
function benchmark_lfmm3d(ns::Int, eps::Float64)
```

- [ ] **Step 2: Replace the hardcoded epsilon in the timed call**

```julia
time = @belapsed lfmm3d($(eps), $(sources); charges=$(charges), pg = 2)
```

- [ ] **Step 3: Parse `eps` and output path from `ARGS`**

```julia
eps = parse(Float64, args[1])
filename = args[2]
```

- [ ] **Step 4: Pass `eps` through the problem-size loop**

```julia
time = benchmark_lfmm3d(n, eps)
```

- [ ] **Step 5: Run a local syntax smoke check**

Run: `julia --project=fmm3d -e 'include("fmm3d/benchmark.jl")' 1e-3 /tmp/fmm3d_smoke.csv`

Expected: the command starts successfully and writes `/tmp/fmm3d_smoke.csv` if the environment is usable; if local runtime is too expensive, at minimum it must fail for an external runtime reason rather than a Julia parse or argument error.

### Task 2: Add The Cluster Submission Script

**Files:**
- Create: `fmm3d/scripts/benchmark_3digits.sbatch`

- [ ] **Step 1: Create a batch script with Genoa resource requests**

```bash
#!/bin/bash
#SBATCH --job-name=fmm3d_3digits
#SBATCH --output=fmm3d/benchmark_3digits_%j.out
#SBATCH --error=fmm3d/benchmark_3digits_%j.err
#SBATCH -p ccm
#SBATCH -C genoa
#SBATCH -N 1
#SBATCH -c 96
#SBATCH --time=06:00:00
```

- [ ] **Step 2: Load the CPU software environment and set paths**

```bash
set -euo pipefail

module load gcc fftw openmpi

ROOT=/mnt/home/xgao1/work/FMM_benchmark
FMM3D_DIR=$ROOT/fmm3d
OUT_DIR=$FMM3D_DIR/data/96_cores_3digits
mkdir -p "$OUT_DIR"
cd "$FMM3D_DIR"
```

- [ ] **Step 3: Run the full thread-count sweep at `eps=1e-3`**

```bash
for t in 1 2 4 8 16 32 48 64 80 96; do
  OMP_NUM_THREADS=$t julia --project=. benchmark.jl 1e-3 "$OUT_DIR/rfmm3d_julia_benchmark_${t}.csv"
done
```

- [ ] **Step 4: Make the script executable if needed**

Run: `chmod +x fmm3d/scripts/benchmark_3digits.sbatch`

Expected: no output, exit code 0

### Task 3: Submit And Verify The Cluster Run

**Files:**
- Use: `fmm3d/scripts/benchmark_3digits.sbatch`

- [ ] **Step 1: Submit the job**

Run: `sbatch fmm3d/scripts/benchmark_3digits.sbatch`

Expected: `Submitted batch job <jobid>`

- [ ] **Step 2: Confirm the job appears in the queue**

Run: `squeue --me`

Expected: a row for `fmm3d_3digits` or the submitted job ID

- [ ] **Step 3: After completion, inspect one output CSV**

Run: `head -5 fmm3d/data/96_cores_3digits/rfmm3d_julia_benchmark_1.csv`

Expected: header `ns,time` followed by numeric rows
