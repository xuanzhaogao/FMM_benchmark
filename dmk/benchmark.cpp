// DMK Laplace benchmark: sweeps problem sizes, outputs (ns,time) CSV.
// Must include tree.hpp to force template instantiation (works around
// symbol-interposition issue with libdmk.so).

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <vector>

#include <dmk.h>
#include <dmk/omp_wrapper.hpp>
#include <dmk/tree.hpp>
#include <dmk/util.hpp>
#include <sctl.hpp>

#ifdef DMK_HAVE_MPI
auto MYCOMM = MPI_COMM_WORLD;
#else
auto MYCOMM = nullptr;
#endif

static const int PROBLEM_SIZES[] = {
    1000, 2000, 4000, 8000, 16000, 32000, 64000, 128000,
    256000, 512000, 1024000
};
static constexpr int N_SIZES = 11;
static constexpr int N_REPEATS = 3;
static constexpr int N_DIM = 3;

template <typename Real>
double time_dmk(int ns, double eps, long seed) {
    sctl::Vector<Real> r_src, r_trg, rnormal, charges, dipstr;
    dmk::util::init_test_data(N_DIM, 1, ns, ns, false, false,
                              r_src, r_trg, rnormal, charges, dipstr, seed);

    pdmk_params params;
    params.n_dim = N_DIM;
    params.eps = eps;
    params.kernel = DMK_LAPLACE;
    params.pgh_src = DMK_POTENTIAL_GRAD;
    params.pgh_trg = DMK_POTENTIAL_GRAD;
    params.log_level = DMK_LOG_OFF;
    params.n_per_leaf = 300;

    const int output_dim = 1 + N_DIM;
    sctl::Vector<Real> pot_src(ns * output_dim), pot_trg(ns * output_dim);
    pot_src.SetZero();
    pot_trg.SetZero();

    double t0 = MY_OMP_GET_WTIME();
    pdmk_tree tree = pdmk_tree_create(MYCOMM, params, ns, &r_src[0], &charges[0],
                                      &rnormal[0], &dipstr[0], ns, &r_trg[0]);
    pdmk_tree_eval(tree, &pot_src[0], &pot_trg[0]);
    pdmk_tree_destroy(tree);
    double elapsed = MY_OMP_GET_WTIME() - t0;

    return elapsed;
}

int main(int argc, char **argv) {
#ifdef DMK_HAVE_MPI
    MPI_Init(&argc, &argv);
    int size, rank;
    MPI_Comm_size(MPI_COMM_WORLD, &size);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    if (size > 1) {
        if (!rank) std::fprintf(stderr, "Not MPI aware\n");
        MPI_Finalize();
        return 0;
    }
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

    for (int i = 0; i < N_SIZES; ++i) {
        const int ns = PROBLEM_SIZES[i];

        std::vector<double> timings(N_REPEATS);
        for (int r = 0; r < N_REPEATS; ++r) {
            timings[r] = time_dmk<double>(ns, eps, 42);
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
