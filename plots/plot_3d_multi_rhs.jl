using CSV, DataFrames
using CairoMakie

nd_values = [2, 4, 8, 16]
all_nd = [1; nd_values]
thread_counts = [1, 2, 4, 8, 16, 32, 48, 64, 80, 96]
nd_colors = [:blue, :red, :green, :orange, :purple]

# Load data: dict (nd, threads) -> DataFrame
data = Dict{Tuple{Int,Int},DataFrame}()
for nd in nd_values
    path = joinpath(@__DIR__, "../fmm3d/data/96_cores_rhs_compare/nd_$nd")
    for t in thread_counts
        df = CSV.read(joinpath(path, "rfmm3d_julia_benchmark_$t.csv"), DataFrame)
        df.time_per_rhs = df.time ./ nd
        data[(nd, t)] = df
    end
end

# Also load nd=1 baseline from 96_cores
begin
    path_baseline = joinpath(@__DIR__, "../fmm3d/data/96_cores")
    for t in thread_counts
        fname = joinpath(path_baseline, "rfmm3d_julia_benchmark_$t.csv")
        if isfile(fname)
            df = CSV.read(fname, DataFrame)
            df.time_per_rhs = df.time ./ 1
            data[(1, t)] = df
        end
    end
end

# --- Per-RHS time vs number of particles, one subplot per thread count, lines = nd ---
begin
    selected_threads = [16, 32, 64]
    fig = Figure(size = (1800, 500), fontsize = 20)

    for (idx, t) in enumerate(selected_threads)
        ax = Axis(fig[1, idx],
            xlabel = "Number of points",
            ylabel = "Time per RHS (s)",
            title = "$t threads",
            xscale = log10, yscale = log10)

        for (j, nd) in enumerate(all_nd)
            if haskey(data, (nd, t))
                df = data[(nd, t)]
                scatterlines!(ax, df.ns, df.time_per_rhs,
                    label = "nd = $nd", linewidth = 2, color = nd_colors[j])
            end
        end
    end

    Legend(fig[1, 4], fig.content[1], labelsize = 14, nbanks = 1)
    save(joinpath(@__DIR__, "benchmark_fmm3d_multi_rhs_per_nd.svg"), fig)
    fig
end
