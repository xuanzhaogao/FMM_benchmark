using FMM3D
using BenchmarkTools
using CSV, DataFrames

const PROBLEM_SIZES = [
    100, 200, 400, 800, 1600, 3200, 6400, 12800,
    25600, 51200, 102400, 204800, 409600, 409600 * 2, 409600 * 4,
]

function benchmark_lfmm3d_multi_rhs(ns::Int, eps::Float64, nd::Int)
    sources = rand(3, ns)
    charges = nd == 1 ? rand(ns) : rand(nd, ns)

    time = @belapsed lfmm3d($(eps), $(sources); charges=$(charges), pg = 2, nd=$(nd))

    @show ns, nd, time

    return time
end

function main(args::Vector{String})
    if length(args) != 3
        error("Usage: julia --project=. benchmark_multi_rhs.jl <eps> <nd> <output.csv>")
    end

    eps = parse(Float64, args[1])
    nd = parse(Int, args[2])
    filename = args[3]

    if nd < 1
        error("nd must be >= 1")
    end

    df = CSV.write(filename, DataFrame(ns = Int[], time = Float64[]))
    for n in PROBLEM_SIZES
        time = benchmark_lfmm3d_multi_rhs(n, eps, nd)
        CSV.write(df, DataFrame(ns = n, time = time), append = true)
    end
    return df
end

main(ARGS)
