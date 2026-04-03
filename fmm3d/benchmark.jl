using FMM3D
using BenchmarkTools
using CSV, DataFrames

function benchmark_lfmm3d(ns::Int, eps::Float64)
    sources = rand(3, ns)
    charges = rand(ns)

    time = @belapsed lfmm3d($(eps), $(sources); charges=$(charges), pg = 2)

    @show ns, time

    return time
end

function main(args::Vector{String})
    if length(args) != 2
        error("Usage: julia --project=. benchmark.jl <eps> <output.csv>")
    end

    eps = parse(Float64, args[1])
    filename = args[2]
    df = CSV.write(filename, DataFrame(ns = Int[], time = Float64[]))
    for n in [100, 200, 400, 800, 1600, 3200, 6400, 12800, 25600, 51200, 102400, 204800, 409600, 409600 * 2, 409600 * 4]
        time = benchmark_lfmm3d(n, eps)
        CSV.write(df, DataFrame(ns = n, time = time), append = true)
    end
    return df
end

main(ARGS)
