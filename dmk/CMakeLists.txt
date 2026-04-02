cmake_minimum_required(VERSION 3.18)
project(dmk_benchmark LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 20)

set(FIDMK_ROOT "/mnt/home/xgao1/codes/FIDMK" CACHE PATH "Path to FIDMK checkout")
set(FIDMK_BUILD "" CACHE PATH "Path to pre-built FIDMK (with libdmk.so)")

find_package(OpenMP REQUIRED)
find_package(MPI REQUIRED)
find_package(BLAS REQUIRED)

find_library(DMK_SHARED_LIB NAMES dmk PATHS "${FIDMK_BUILD}" NO_DEFAULT_PATH)
if(NOT DMK_SHARED_LIB)
  message(FATAL_ERROR "Cannot find libdmk.so in ${FIDMK_BUILD}. Build FIDMK first.")
endif()

set(DMK_INCLUDES
  "${FIDMK_ROOT}/include"
  "${FIDMK_ROOT}/extern/SCTL/include"
  "${FIDMK_ROOT}/extern/nda/c++"
  "${FIDMK_BUILD}/extern/nda/deps/itertools_src/c++"
  "${FIDMK_ROOT}/extern/spdlog/include"
  "${FIDMK_ROOT}/extern/doctest"
)

add_executable(benchmark benchmark.cpp)
target_include_directories(benchmark PRIVATE ${DMK_INCLUDES})
target_compile_options(benchmark PRIVATE
  -DSCTL_HAVE_LIBMVEC -march=native -DSCTL_MAX_DEPTH=62
  -DDMK_HAVE_OPENMP -DSCTL_HAVE_MPI -DDMK_HAVE_MPI
  -DDOCTEST_CONFIG_DISABLE -DSCTL_PROFILE=-1
)
target_link_libraries(benchmark PRIVATE
  "${DMK_SHARED_LIB}"
  "${FIDMK_BUILD}/extern/nda/c++/nda/libnda_c.a"
  OpenMP::OpenMP_CXX MPI::MPI_CXX BLAS::BLAS
)
set_target_properties(benchmark PROPERTIES
  BUILD_RPATH "${FIDMK_BUILD}"
  RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
)
