# DMK Benchmark Design

**Date:** 2026-04-02  
**Author:** Xuanzhao Gao  
**Scope:** Add a DMK runtime benchmark under `FMM_benchmark/dmk/`, mirroring the structure of `fmm3d/`.

---

## Goal

Benchmark the runtime of DMK (3D Laplace, potential + gradient at sources) across:
- **Problem sizes:** 15 values doubling from 100 to 1,638,400 (same as `fmm3d/benchmark.jl`)
- **Thread counts:** 1, 2, 4, 8, 16, 32, 48, 64, 80, 96 (same as `fmm3d/Makefile`)
- **Precision levels:** `eps = 1e-3` (3 digits) and `eps = 1e-6` (6 digits)

Results are saved as CSVs and visualized as runtime + speedup plots.

---

## Directory Layout

```
FMM_benchmark/dmk/
├── benchmark.cpp              # C++ benchmark executable
├── CMakeLists.txt             # Builds benchmark, links FIDMK
├── Makefile                   # Runs all (eps × thread) combos
├── data/
│   ├── 3digits/               # dmk_benchmark_{1,2,4,8,16,32,48,64,80,96}.csv
│   └── 6digits/               # same filenames
└── scripts/
    ├── benchmark.sbatch       # SLURM: 1 genoa node, 96 cores
    └── plot.py                # Runtime + speedup plots (matplotlib)
```

---

## Components

### `benchmark.cpp`

**Interface:** `./benchmark <eps> <output.csv>`

**Algorithm per problem size:**
1. Generate `ns` random 3D sources uniformly in [0,1]³ and `ns` random charges.
2. Call `pdmk()` (FIDMK one-shot, Laplace kernel, `pgh_src = DMK_PGH_PG`) — potential and gradient at sources, no targets.
3. Repeat 3 times, record median wall-clock time.
4. Append row `ns,time` to the output CSV.

**Problem sizes:** `[100, 200, 400, 800, 1600, 3200, 6400, 12800, 25600, 51200, 102400, 204800, 409600, 819200, 1638400]`

**Timing:** `std::chrono::steady_clock`, median of 3 repeats.

**CSV format:**
```
ns,time
100,0.001234
200,0.002345
...
```

### `CMakeLists.txt`

- `cmake_minimum_required(VERSION 3.18)`
- `FIDMK_ROOT` cache variable pointing to `/mnt/home/xgao1/codes/FIDMK`
- `add_subdirectory(FIDMK_ROOT)` to get the `dmk` target
- Single executable `benchmark` linking against `dmk`
- `RUNTIME_OUTPUT_DIRECTORY` set to `${CMAKE_BINARY_DIR}/bin`

### `Makefile`

Runs all 20 combinations (10 thread counts × 2 eps). Each line:
```makefile
OMP_NUM_THREADS=N ./build/bin/benchmark EPS data/Xdigits/dmk_benchmark_N.csv
```

Targets: `all`, `3digits`, `6digits`, `build`.

### `scripts/benchmark.sbatch`

```
#SBATCH -p ccm
#SBATCH -C genoa
#SBATCH -N 1
#SBATCH -c 96
#SBATCH --time=06:00:00
```

Steps: load `gcc fftw openmpi`, cmake build, `make all`.

### `scripts/plot.py`

Two figures (one per precision level), each with two panels:
- **Left:** Runtime vs number of sources (log-log), one curve per thread count
- **Right:** Speedup vs number of sources (log-log), relative to 1-thread run, with ideal speedup line

Output: `plots/dmk_3digits.{svg,png}` and `plots/dmk_6digits.{svg,png}`

---

## Data Flow

```
benchmark.sbatch
  └── cmake build
  └── make all
        ├── [eps=1e-3, omp=1..96] → data/3digits/dmk_benchmark_N.csv
        └── [eps=1e-6, omp=1..96] → data/6digits/dmk_benchmark_N.csv
  └── python3 scripts/plot.py → plots/dmk_3digits.{svg,png}
                               → plots/dmk_6digits.{svg,png}
```

---

## Constraints

- FIDMK is at `/mnt/home/xgao1/codes/FIDMK` (C++ library, C interface via `dmk.h`)
- FMM3D dependency not needed for this benchmark (no reference comparison, pure timing)
- `pdmk()` is the one-shot convenience function; it is not MPI-parallel — only OMP threading
- Genoa node has 96 physical cores; thread counts match `fmm3d/Makefile` exactly
- Existing files in `dmk/` from a prior attempt will be replaced

---

## Out of Scope

- Accuracy validation (no reference comparison)
- MPI multi-rank runs
- Precision levels beyond 1e-3 and 1e-6
- Julia wrapper for DMK
