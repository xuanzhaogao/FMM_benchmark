# FMM3D Multi-RHS Benchmark Design

**Goal:** Benchmark single-RHS versus multi-RHS FMM3D performance across the same point-count sweep already used by the repo's existing FMM3D benchmark workflow.

**Architecture:** Add a separate Julia benchmark entrypoint that accepts `eps`, `nd`, and an output CSV path. The benchmark will use the same `ns` sweep as the current single-RHS benchmark, but generate `charges` with shape `(n)` for `nd=1` and `(nd,n)` for `nd>1`, then call `lfmm3d(...; charges=..., nd=nd, pg=2)`.

**Data Layout:**
- Existing single-RHS benchmark data stays untouched.
- New results go in `fmm3d/data/96_cores_rhs_compare/`.
- Subdirectories are partitioned by RHS count:
  - `fmm3d/data/96_cores_rhs_compare/nd_2/`
  - `fmm3d/data/96_cores_rhs_compare/nd_4/`
  - `fmm3d/data/96_cores_rhs_compare/nd_8/`
  - `fmm3d/data/96_cores_rhs_compare/nd_16/`
- Each subdirectory uses the current per-thread filename convention:
  `rfmm3d_julia_benchmark_<threads>.csv`

**Execution Flow:**
1. Submit a separate Genoa SLURM job so this benchmark is isolated from the running 3-digit rerun.
2. For each `nd` in `{2,4,8,16}`, run the same thread-count sweep `{1,2,4,8,16,32,48,64,80,96}`.
3. For each `(nd, threads)` pair, write one CSV containing `ns,time` rows for the full point-count sweep.

**Validation:**
- Verify the new benchmark script parses arguments and reaches the usage guard or execution path locally.
- Submit the SLURM job and capture the job ID.
- Confirm the job is in the queue.
- Inspect one CSV from `nd_2` and one CSV from a higher multi-RHS case such as `nd_8`.
