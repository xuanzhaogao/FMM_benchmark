# DMK Benchmark Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Benchmark DMK Laplace (potential + gradient) runtime across problem sizes and thread counts, mirroring the `fmm3d/` benchmark structure.

**Architecture:** A C++ executable sweeps 15 problem sizes per invocation, writing `(ns,time)` CSV. A Makefile drives all 20 runs (2 eps x 10 thread counts). A Python script generates runtime and speedup plots.

**Tech Stack:** C++ (FIDMK library), CMake, Make, Python/matplotlib, SLURM

---

### Task 1: Clean up prior files in `dmk/`

**Files:**
- Delete: `dmk/CMakeLists.txt`, `dmk/scripts/run_matrix.sh`, `dmk/scripts/benchmark_genoa.sbatch`, `dmk/scripts/plot.py`
- Delete: `dmk/build/` directory

- [ ] **Step 1: Remove stale files from prior attempt**

```bash
cd /mnt/home/xgao1/work/FMM_benchmark
rm -rf dmk/CMakeLists.txt dmk/scripts dmk/build dmk/plots dmk/benchmark_genoa_*.out dmk/benchmark_genoa_*.err
mkdir -p dmk/data/3digits dmk/data/6digits dmk/scripts dmk/plots
```

- [ ] **Step 2: Commit cleanup**

```bash
git add -A dmk/
git commit -m "clean: remove stale dmk benchmark files"
```

---

### Task 2: Write `dmk/benchmark.cpp`

**Files:**
- Create: `dmk/benchmark.cpp`

This is the core benchmark. It takes `<eps> <output.csv>` as CLI args, sweeps 15 problem sizes, and writes one `(ns,time)` row per size.

- [ ] **Step 1: Create `dmk/benchmark.cpp`**

```cpp
#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <random>
#include <string>
#include <vector>

#include <dmk.h>

#ifdef DMK_HAVE_MPI
#include <mpi.h>
#define MYCOMM MPI_COMM_WORLD
#else
#define MYCOMM nullptr
#endif

static const int PROBLEM_SIZES[] = {
    100, 200, 400, 800, 1600, 3200, 6400, 12800,
    25600, 51200, 102400, 204800, 409600, 819200, 1638400
};
static constexpr int N_SIZES = 15;
static constexpr int N_REPEATS = 3;
static constexpr int N_DIM = 3;

double time_dmk(int ns, double eps, const double *sources, const double *charges) {
    pdmk_params params{};
    params.n_dim = N_DIM;
    params.eps = eps;
    params.kernel = DMK_LAPLACE;
    params.pgh_src = DMK_POTENTIAL_GRAD;
    params.pgh_trg = DMK_POTENTIAL;
    params.log_level = DMK_LOG_OFF;
    params.n_per_leaf = 300;

    const int output_dim = 1 + N_DIM; // potential + gradient
    std::vector<double> pot_src(static_cast<size_t>(ns) * output_dim, 0.0);

    auto t0 = std::chrono::steady_clock::now();

    pdmk_tree tree = pdmk_tree_create(MYCOMM, params, ns, sources, charges,
                                      nullptr, nullptr, 0, nullptr);
    pdmk_tree_eval(tree, pot_src.data(), nullptr);
    pdmk_tree_destroy(tree);

    auto t1 = std::chrono::steady_clock::now();
    return std::chrono::duration<double>(t1 - t0).count();
}

int main(int argc, char **argv) {
#ifdef DMK_HAVE_MPI
    MPI_Init(&argc, &argv);
#endif

    if (argc != 3) {
        std::fprintf(stderr, "Usage: %s <eps> <output.csv>\n", argv[0]);
#ifdef DMK_HAVE_MPI
        MPI_Finalize();
#endif
        return 1;
    }

    const double eps = std::atof(argv[1]);
    const char *output_path = argv[2];

    std::ofstream csv(output_path);
    if (!csv.is_open()) {
        std::fprintf(stderr, "Cannot open %s for writing\n", output_path);
#ifdef DMK_HAVE_MPI
        MPI_Finalize();
#endif
        return 1;
    }
    csv << "ns,time\n";

    std::mt19937_64 rng(42);
    std::uniform_real_distribution<double> dist(0.0, 1.0);

    for (int i = 0; i < N_SIZES; ++i) {
        const int ns = PROBLEM_SIZES[i];

        std::vector<double> sources(static_cast<size_t>(ns) * N_DIM);
        std::vector<double> charges(ns);
        for (auto &v : sources) v = dist(rng);
        for (auto &v : charges) v = dist(rng);

        // Collect N_REPEATS timings, take median
        std::vector<double> timings(N_REPEATS);
        for (int r = 0; r < N_REPEATS; ++r) {
            timings[r] = time_dmk(ns, eps, sources.data(), charges.data());
        }
        std::sort(timings.begin(), timings.end());
        double median = timings[N_REPEATS / 2];

        std::printf("ns=%d eps=%.0e time=%.6f\n", ns, eps, median);
        csv << ns << "," << median << "\n";
        csv.flush();
    }

    csv.close();

#ifdef DMK_HAVE_MPI
    MPI_Finalize();
#endif
    return 0;
}
```

- [ ] **Step 2: Verify file created**

```bash
wc -l dmk/benchmark.cpp
```

Expected: ~95 lines

- [ ] **Step 3: Commit**

```bash
git add dmk/benchmark.cpp
git commit -m "feat: add DMK benchmark executable source"
```

---

### Task 3: Write `dmk/CMakeLists.txt`

**Files:**
- Create: `dmk/CMakeLists.txt`

- [ ] **Step 1: Create `dmk/CMakeLists.txt`**

```cmake
cmake_minimum_required(VERSION 3.18)
project(dmk_benchmark LANGUAGES CXX)

set(FIDMK_ROOT "/mnt/home/xgao1/codes/FIDMK" CACHE PATH "Path to FIDMK checkout")
set(CMAKE_INSTALL_PREFIX "${CMAKE_BINARY_DIR}/install" CACHE PATH "" FORCE)
set(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT FALSE)

set(DMK_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(DMK_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(DMK_BUILD_PVFMM OFF CACHE BOOL "" FORCE)
set(DMK_BUILD_REFERENCE OFF CACHE BOOL "" FORCE)

add_subdirectory("${FIDMK_ROOT}" fidmk)

add_executable(benchmark benchmark.cpp)
target_link_libraries(benchmark PRIVATE dmk)
target_include_directories(benchmark PRIVATE "${FIDMK_ROOT}/extern/nda/c++")
set_target_properties(benchmark PROPERTIES
  RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
)
```

- [ ] **Step 2: Commit**

```bash
git add dmk/CMakeLists.txt
git commit -m "feat: add CMakeLists for DMK benchmark"
```

---

### Task 4: Write `dmk/Makefile`

**Files:**
- Create: `dmk/Makefile`

Mirrors `fmm3d/Makefile` — one line per (eps, thread_count) combo.

- [ ] **Step 1: Create `dmk/Makefile`**

```makefile
BENCHMARK = ./build/bin/benchmark

all: build 3digits 6digits

build:
	module load gcc fftw openmpi && \
	cmake -S . -B build -DFIDMK_ROOT=/mnt/home/xgao1/codes/FIDMK && \
	cmake --build build --target benchmark -j4

3digits:
	OMP_NUM_THREADS=1  $(BENCHMARK) 1e-3 data/3digits/dmk_benchmark_1.csv
	OMP_NUM_THREADS=2  $(BENCHMARK) 1e-3 data/3digits/dmk_benchmark_2.csv
	OMP_NUM_THREADS=4  $(BENCHMARK) 1e-3 data/3digits/dmk_benchmark_4.csv
	OMP_NUM_THREADS=8  $(BENCHMARK) 1e-3 data/3digits/dmk_benchmark_8.csv
	OMP_NUM_THREADS=16 $(BENCHMARK) 1e-3 data/3digits/dmk_benchmark_16.csv
	OMP_NUM_THREADS=32 $(BENCHMARK) 1e-3 data/3digits/dmk_benchmark_32.csv
	OMP_NUM_THREADS=48 $(BENCHMARK) 1e-3 data/3digits/dmk_benchmark_48.csv
	OMP_NUM_THREADS=64 $(BENCHMARK) 1e-3 data/3digits/dmk_benchmark_64.csv
	OMP_NUM_THREADS=80 $(BENCHMARK) 1e-3 data/3digits/dmk_benchmark_80.csv
	OMP_NUM_THREADS=96 $(BENCHMARK) 1e-3 data/3digits/dmk_benchmark_96.csv

6digits:
	OMP_NUM_THREADS=1  $(BENCHMARK) 1e-6 data/6digits/dmk_benchmark_1.csv
	OMP_NUM_THREADS=2  $(BENCHMARK) 1e-6 data/6digits/dmk_benchmark_2.csv
	OMP_NUM_THREADS=4  $(BENCHMARK) 1e-6 data/6digits/dmk_benchmark_4.csv
	OMP_NUM_THREADS=8  $(BENCHMARK) 1e-6 data/6digits/dmk_benchmark_8.csv
	OMP_NUM_THREADS=16 $(BENCHMARK) 1e-6 data/6digits/dmk_benchmark_16.csv
	OMP_NUM_THREADS=32 $(BENCHMARK) 1e-6 data/6digits/dmk_benchmark_32.csv
	OMP_NUM_THREADS=48 $(BENCHMARK) 1e-6 data/6digits/dmk_benchmark_48.csv
	OMP_NUM_THREADS=64 $(BENCHMARK) 1e-6 data/6digits/dmk_benchmark_64.csv
	OMP_NUM_THREADS=80 $(BENCHMARK) 1e-6 data/6digits/dmk_benchmark_80.csv
	OMP_NUM_THREADS=96 $(BENCHMARK) 1e-6 data/6digits/dmk_benchmark_96.csv

plot:
	python3 scripts/plot.py

.PHONY: all build 3digits 6digits plot
```

- [ ] **Step 2: Commit**

```bash
git add dmk/Makefile
git commit -m "feat: add Makefile for DMK benchmark runs"
```

---

### Task 5: Write `dmk/scripts/plot.py`

**Files:**
- Create: `dmk/scripts/plot.py`

Generates runtime and speedup plots per precision level, matching the style of `plots/plot_3d.jl`.

- [ ] **Step 1: Create `dmk/scripts/plot.py`**

```python
#!/usr/bin/env python3
"""Generate runtime and speedup plots for DMK benchmark."""

import csv
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.ticker as ticker

THREAD_COUNTS = [1, 2, 4, 8, 16, 32, 48, 64, 80, 96]
COLORS = {
    1: "#1f77b4", 2: "#ff7f0e", 4: "#2ca02c", 8: "#d62728",
    16: "#9467bd", 32: "#8c564b", 48: "#e377c2", 64: "#7f7f7f",
    80: "#bcbd22", 96: "#17becf",
}
DMK_DIR = Path(__file__).resolve().parent.parent


def load_csv(path: Path) -> tuple:
    ns, times = [], []
    with path.open() as f:
        reader = csv.DictReader(f)
        for row in reader:
            ns.append(int(row["ns"]))
            times.append(float(row["time"]))
    return ns, times


def plot_digits(digits_dir: Path, label: str, output_stem: str):
    data = {}
    for t in THREAD_COUNTS:
        p = digits_dir / f"dmk_benchmark_{t}.csv"
        if p.exists():
            data[t] = load_csv(p)

    if not data:
        print(f"No data found in {digits_dir}, skipping")
        return

    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 5))

    # Left panel: runtime
    for t in THREAD_COUNTS:
        if t not in data:
            continue
        ns, times = data[t]
        ax1.plot(ns, times, marker="o", color=COLORS[t],
                 label=f"{t} thread{'s' if t > 1 else ''}", linewidth=2)

    ax1.set_xscale("log")
    ax1.set_yscale("log")
    ax1.set_xlabel("Number of points")
    ax1.set_ylabel("Time (s)")
    ax1.set_title(f"DMK Run Time ({label})")
    ax1.grid(True, which="both", alpha=0.3)

    # Right panel: speedup
    if 1 in data:
        ns_ref, t_ref = data[1]
        for t in THREAD_COUNTS:
            if t <= 1 or t not in data:
                continue
            ns, times = data[t]
            n = min(len(t_ref), len(times))
            speedup = [t_ref[i] / times[i] for i in range(n)]
            ax2.plot(ns[:n], speedup, marker="o", color=COLORS[t],
                     label=f"{t} threads", linewidth=2)

        ax2.plot(ns_ref, [1] * len(ns_ref), "--", color="gray",
                 linewidth=1, label="ideal=1")

    ax2.set_xscale("log")
    ax2.set_yscale("log")
    ax2.set_xlabel("Number of points")
    ax2.set_ylabel("Speedup")
    ax2.set_title(f"DMK Speedup ({label})")
    ax2.yaxis.set_major_formatter(ticker.ScalarFormatter())
    ax2.yaxis.set_minor_formatter(ticker.NullFormatter())
    ax2.grid(True, which="both", alpha=0.3)

    handles, labels = ax1.get_legend_handles_labels()
    fig.legend(handles, labels, loc="center right", fontsize=9,
               bbox_to_anchor=(1.12, 0.5))

    fig.tight_layout()
    out_dir = DMK_DIR / "plots"
    out_dir.mkdir(exist_ok=True)
    fig.savefig(out_dir / f"{output_stem}.svg", format="svg",
                bbox_inches="tight")
    fig.savefig(out_dir / f"{output_stem}.png", dpi=150,
                bbox_inches="tight")
    print(f"Saved {out_dir / output_stem}.{{svg,png}}")
    plt.close(fig)


def main():
    data_dir = DMK_DIR / "data"
    plot_digits(data_dir / "3digits", "3 digits / eps=1e-3", "dmk_3digits")
    plot_digits(data_dir / "6digits", "6 digits / eps=1e-6", "dmk_6digits")


if __name__ == "__main__":
    main()
```

- [ ] **Step 2: Commit**

```bash
git add dmk/scripts/plot.py
git commit -m "feat: add plotting script for DMK benchmark"
```

---

### Task 6: Write `dmk/scripts/benchmark.sbatch`

**Files:**
- Create: `dmk/scripts/benchmark.sbatch`

- [ ] **Step 1: Create `dmk/scripts/benchmark.sbatch`**

```bash
#!/bin/bash
#SBATCH --job-name=dmk_bench
#SBATCH --output=dmk/benchmark_%j.out
#SBATCH --error=dmk/benchmark_%j.err
#SBATCH -p ccm
#SBATCH -C genoa
#SBATCH -N 1
#SBATCH -c 96
#SBATCH --time=06:00:00

set -euo pipefail

cd /mnt/home/xgao1/work/FMM_benchmark

module load gcc fftw openmpi

# Build
cd dmk
cmake -S . -B build -DFIDMK_ROOT=/mnt/home/xgao1/codes/FIDMK
cmake --build build --target benchmark -j4

# Run all benchmarks
make 3digits
make 6digits

# Generate plots
python3 scripts/plot.py
```

- [ ] **Step 2: Commit**

```bash
git add dmk/scripts/benchmark.sbatch
git commit -m "feat: add SLURM script for DMK benchmark on genoa"
```

---

### Task 7: Build, submit, and verify

- [ ] **Step 1: Cancel any stale job from prior attempt**

```bash
scancel 6184352
```

- [ ] **Step 2: Submit the new job**

```bash
cd /mnt/home/xgao1/work/FMM_benchmark
sbatch dmk/scripts/benchmark.sbatch
```

- [ ] **Step 3: Monitor job start**

```bash
squeue --me
```

Expected: job running on a genoa node.

- [ ] **Step 4: After job completes, verify CSV output**

```bash
ls dmk/data/3digits/ dmk/data/6digits/
head -3 dmk/data/3digits/dmk_benchmark_1.csv
```

Expected: 10 CSV files per folder, each with `ns,time` header + 15 data rows.

- [ ] **Step 5: Verify plots**

```bash
ls dmk/plots/
```

Expected: `dmk_3digits.svg`, `dmk_3digits.png`, `dmk_6digits.svg`, `dmk_6digits.png`

- [ ] **Step 6: Commit results**

```bash
git add dmk/data/ dmk/plots/
git commit -m "data: add DMK benchmark results and plots (genoa, 96 cores)"
```
