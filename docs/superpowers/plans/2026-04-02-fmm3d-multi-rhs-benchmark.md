# FMM3D Multi-RHS Benchmark Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a separate FMM3D benchmark workflow that compares single-RHS and multi-RHS performance across the existing point-count sweep and submit it on the Genoa cluster.

**Architecture:** Keep the current single-RHS benchmark intact. Add a dedicated Julia entrypoint for multi-RHS comparisons, then drive it with a separate SLURM script that sweeps selected RHS counts and thread counts into a new dataset directory.

**Tech Stack:** Julia, FMM3D.jl, SLURM, bash

---

### Task 1: Add The Multi-RHS Benchmark Entry Point

**Files:**
- Create: `fmm3d/benchmark_multi_rhs.jl`

- [ ] **Step 1: Add argument parsing for `eps`, `nd`, and output path**

```julia
if length(args) != 3
    error("Usage: julia --project=. benchmark_multi_rhs.jl <eps> <nd> <output.csv>")
end

eps = parse(Float64, args[1])
nd = parse(Int, args[2])
filename = args[3]
```

- [ ] **Step 2: Build charges in single-RHS or multi-RHS shape**

```julia
charges = nd == 1 ? rand(ns) : rand(nd, ns)
```

- [ ] **Step 3: Time `lfmm3d` with explicit `nd`**

```julia
time = @belapsed lfmm3d($(eps), $(sources); charges=$(charges), pg = 2, nd=$(nd))
```

- [ ] **Step 4: Write the same `ns,time` CSV schema as the existing benchmark**

```julia
df = CSV.write(filename, DataFrame(ns = Int[], time = Float64[]))
```

- [ ] **Step 5: Run a local CLI smoke check**

Run: `julia --project=fmm3d fmm3d/benchmark_multi_rhs.jl`

Expected: fail with the explicit usage message, not with a parse error

### Task 2: Add The Cluster Submission Script

**Files:**
- Create: `fmm3d/scripts/benchmark_multi_rhs.sbatch`

- [ ] **Step 1: Create the Slurm header**

```bash
#!/bin/bash
#SBATCH --job-name=fmm3d_rhs
#SBATCH --output=fmm3d/benchmark_multi_rhs_%j.out
#SBATCH --error=fmm3d/benchmark_multi_rhs_%j.err
#SBATCH -p ccm
#SBATCH -C genoa
#SBATCH -N 1
#SBATCH -c 96
#SBATCH --time=06:00:00
```

- [ ] **Step 2: Set up environment and output root**

```bash
set -euo pipefail

module load gcc fftw openmpi

ROOT=/mnt/home/xgao1/work/FMM_benchmark
FMM3D_DIR=$ROOT/fmm3d
OUT_ROOT=$FMM3D_DIR/data/96_cores_rhs_compare
cd "$FMM3D_DIR"
```

- [ ] **Step 3: Sweep `nd` and thread counts**

```bash
for nd in 2 4 8 16; do
  OUT_DIR=$OUT_ROOT/nd_${nd}
  mkdir -p "$OUT_DIR"
  for t in 1 2 4 8 16 32 48 64 80 96; do
    OMP_NUM_THREADS=$t julia --project=. benchmark_multi_rhs.jl 1e-3 "$nd" "$OUT_DIR/rfmm3d_julia_benchmark_${t}.csv"
  done
done
```

- [ ] **Step 4: Make the script executable**

Run: `chmod +x fmm3d/scripts/benchmark_multi_rhs.sbatch`

Expected: exit code 0

### Task 3: Submit And Verify The Comparison Run

**Files:**
- Use: `fmm3d/scripts/benchmark_multi_rhs.sbatch`

- [ ] **Step 1: Submit the job**

Run: `sbatch fmm3d/scripts/benchmark_multi_rhs.sbatch`

Expected: `Submitted batch job <jobid>`

- [ ] **Step 2: Confirm it is queued or running**

Run: `squeue --me`

Expected: a row for `fmm3d_rhs`

- [ ] **Step 3: Inspect example output files**

Run: `head -5 fmm3d/data/96_cores_rhs_compare/nd_2/rfmm3d_julia_benchmark_1.csv`

Expected: header `ns,time`

Run: `head -5 fmm3d/data/96_cores_rhs_compare/nd_8/rfmm3d_julia_benchmark_1.csv`

Expected: header `ns,time`
