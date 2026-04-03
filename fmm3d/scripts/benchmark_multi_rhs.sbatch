#!/bin/bash
#SBATCH --job-name=fmm3d_rhs
#SBATCH --output=fmm3d/benchmark_multi_rhs_%j.out
#SBATCH --error=fmm3d/benchmark_multi_rhs_%j.err
#SBATCH -p ccm
#SBATCH -C genoa
#SBATCH -N 1
#SBATCH -c 96
#SBATCH --time=06:00:00

set -euo pipefail

module load gcc fftw openmpi

ROOT=/mnt/home/xgao1/work/FMM_benchmark
FMM3D_DIR=$ROOT/fmm3d
OUT_ROOT=$FMM3D_DIR/data/96_cores_rhs_compare

cd "$FMM3D_DIR"

for nd in 2 4 8 16; do
  OUT_DIR=$OUT_ROOT/nd_${nd}
  mkdir -p "$OUT_DIR"
  for t in 1 2 4 8 16 32 48 64 80 96; do
    OMP_NUM_THREADS=$t julia --project=. benchmark_multi_rhs.jl 1e-3 "$nd" "$OUT_DIR/rfmm3d_julia_benchmark_${t}.csv"
  done
done
