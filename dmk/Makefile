BENCHMARK = mpiexec -n 1 ./build/bin/benchmark

all: build 3digits 6digits

build:
	cmake -S . -B build \
		-DFIDMK_ROOT=/mnt/home/xgao1/codes/FIDMK \
		-DFIDMK_BUILD=/mnt/home/xgao1/codes/FIDMK/build_genoa \
		-DCMAKE_BUILD_TYPE=Release
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
