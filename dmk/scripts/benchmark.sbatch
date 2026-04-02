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

FIDMK_ROOT=/mnt/home/xgao1/codes/FIDMK
FIDMK_BUILD=${FIDMK_ROOT}/build_genoa
DMK_DIR=/mnt/home/xgao1/work/FMM_benchmark/dmk

module load gcc fftw openmpi

# Build benchmark (FIDMK already built on genoa at build_genoa)
cd "$DMK_DIR"
cmake -S . -B build \
  -DFIDMK_ROOT="$FIDMK_ROOT" \
  -DFIDMK_BUILD="$FIDMK_BUILD" \
  -DCMAKE_BUILD_TYPE=Release
cmake --build build --target benchmark -j4

# Run all benchmarks
make 3digits
make 6digits

# Generate plots
python3 scripts/plot.py
