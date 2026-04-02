using CSV, DataFrames
using CairoMakie

begin
    path_to_data = joinpath(@__DIR__, "../dmk/data/3digits/")

    df_1 = CSV.read(joinpath(path_to_data, "dmk_benchmark_1.csv"), DataFrame)
    df_2 = CSV.read(joinpath(path_to_data, "dmk_benchmark_2.csv"), DataFrame)
    df_4 = CSV.read(joinpath(path_to_data, "dmk_benchmark_4.csv"), DataFrame)
    df_8 = CSV.read(joinpath(path_to_data, "dmk_benchmark_8.csv"), DataFrame)
    df_16 = CSV.read(joinpath(path_to_data, "dmk_benchmark_16.csv"), DataFrame)
    df_32 = CSV.read(joinpath(path_to_data, "dmk_benchmark_32.csv"), DataFrame)
    df_48 = CSV.read(joinpath(path_to_data, "dmk_benchmark_48.csv"), DataFrame)
    df_64 = CSV.read(joinpath(path_to_data, "dmk_benchmark_64.csv"), DataFrame)
    df_96 = CSV.read(joinpath(path_to_data, "dmk_benchmark_96.csv"), DataFrame)
end

begin
    fig = Figure(size = (1200, 500), fontsize = 20)
    ax = Axis(fig[1, 1], xlabel = "Number of points", ylabel = "Time (s)", title = "DMK Run Time", xscale = log10, yscale = log10)  

    scatterlines!(ax, df_1.ns, df_1.time, label = "1 thread", linewidth = 2, color = :blue)
    scatterlines!(ax, df_2.ns, df_2.time, label = "2 threads", linewidth = 2, color = :red)
    scatterlines!(ax, df_4.ns, df_4.time, label = "4 threads", linewidth = 2, color = :green)
    scatterlines!(ax, df_8.ns, df_8.time, label = "8 threads", linewidth = 2, color = :orange)
    scatterlines!(ax, df_16.ns, df_16.time, label = "16 threads", linewidth = 2, color = :purple)
    scatterlines!(ax, df_32.ns, df_32.time, label = "32 threads", linewidth = 2, color = :brown)
    scatterlines!(ax, df_48.ns, df_48.time, label = "48 threads", linewidth = 2, color = :pink)
    scatterlines!(ax, df_64.ns, df_64.time, label = "64 threads", linewidth = 2, color = :gray)
    scatterlines!(ax, df_96.ns, df_96.time, label = "96 threads", linewidth = 2, color = :black)

    ax2 = Axis(fig[1, 2], xlabel = "Number of points", ylabel = "Speedup", title = "DMK Speedup", xscale = log10, yscale = log10, yticks = [1, 2, 4, 8, 16, 32, 48, 64, 96])
    # scatterlines!(ax2, df_1.ns, df_1.time / df_1.time, label = "1 thread", linewidth = 2, color = :blue)    

    scatterlines!(ax2, df_2.ns,  df_1.time ./ df_2.time, label = "2 threads", linewidth = 2, color = :red)
    scatterlines!(ax2, df_4.ns,  df_1.time ./ df_4.time, label = "4 threads", linewidth = 2, color = :green)
    scatterlines!(ax2, df_8.ns,  df_1.time ./ df_8.time, label = "8 threads", linewidth = 2, color = :orange)
    scatterlines!(ax2, df_16.ns,  df_1.time ./ df_16.time, label = "16 threads", linewidth = 2, color = :purple)
    scatterlines!(ax2, df_32.ns,  df_1.time ./ df_32.time, label = "32 threads", linewidth = 2, color = :brown)
    scatterlines!(ax2, df_48.ns,  df_1.time ./ df_48.time, label = "48 threads", linewidth = 2, color = :pink)
    scatterlines!(ax2, df_64.ns,  df_1.time ./ df_64.time, label = "64 threads", linewidth = 2, color = :gray)
    scatterlines!(ax2, df_96.ns,  df_1.time ./ df_96.time, label = "96 threads", linewidth = 2, color = :black)

    Legend(fig[1, 3], ax, position = :lt, labelsize = 12, nbanks = 1)
    save("dmk_benchmark.svg", fig)
    fig
end