# FMM3D 3-Digit Rerun Design

**Goal:** Re-run the FMM3D Julia benchmark at 3-digit accuracy (`eps=1e-3`) on the Genoa cluster and store the results as a new dataset without overwriting the existing 96-core benchmark outputs.

**Architecture:** Keep the current FMM3D benchmark driver, but parameterize it so `eps` is a command-line argument instead of a hardcoded constant. Add a dedicated SLURM script under `fmm3d/scripts/` that runs the existing thread-count sweep and writes CSV files into a new dataset directory, `fmm3d/data/96_cores_3digits/`.

**Data Layout:**
- Existing data remains in `fmm3d/data/96_cores/`
- New 3-digit data goes in `fmm3d/data/96_cores_3digits/`
- Filenames remain `rfmm3d_julia_benchmark_<threads>.csv`

**Execution Flow:**
1. Submit a single batch job on a Genoa node.
2. Load the cluster module environment needed for Julia execution.
3. Run the benchmark for thread counts `1,2,4,8,16,32,48,64,80,96`.
4. Write all CSV outputs into `fmm3d/data/96_cores_3digits/`.

**Validation:**
- Verify the benchmark script accepts `eps` and output path arguments.
- Verify the batch script creates the new dataset directory before running.
- Submit the SLURM job and capture the job ID.
- After completion, inspect the output directory and one generated CSV file.
