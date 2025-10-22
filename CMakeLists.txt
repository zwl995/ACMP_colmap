cmake_minimum_required (VERSION 2.8)
project (ACMP)

#--- CMake configuration
set(CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

find_package(CUDA 6.0 REQUIRED ) # For Cuda Managed Memory and c++11
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)  # 确保使用指定标准
find_package(OpenCV REQUIRED )
find_package(Eigen3 REQUIRED)

include_directories(
    ${OpenCV_INCLUDE_DIRS}
    ${EIGEN3_INCLUDE_DIRS}
    )
include_directories(.
    ${CMAKE_SOURCE_DIR}
    ${CMAKE_SOURCE_DIR}/src
    )

# glog
find_package(Gflags REQUIRED)
find_package(Glog REQUIRED)

# by zwl ========================================
find_package(Boost REQUIRED COMPONENTS program_options filesystem system)
file(GLOB_RECURSE LIB_SOURCES 
    "src/threadpool/*.cpp"
    "src/threadpool/*.cc"
    "src/threadpool/*.c"
    "src/threadpool/*.cxx"
)
add_library(threadpool_lib 
            SHARED
            ${LIB_SOURCES})
target_link_libraries(threadpool_lib PRIVATE
                    Boost::program_options
                    Boost::filesystem
                    Boost::system
                    glog::glog
)
#===============================================

include_directories(${GFLAGS_INCLUDE_DIRS} ${GLOG_INCLUDE_DIRS})

set(CUDA_NVCC_FLAGS ${CUDA_NVCC_FLAGS};-O3 --use_fast_math --maxrregcount=128 --ptxas-options=-v -std=c++17 --compiler-options -Wall)

if(CMAKE_COMPILER_IS_GNUCXX)
    # add_definitions(-std=c++11)
    add_definitions(-pthread)
    add_definitions(-Wall)
    add_definitions(-Wextra)
    add_definitions(-pedantic)
    add_definitions(-Wno-unused-function)
    add_definitions(-Wno-switch)
    set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} -O3 -ffast-math -march=native") # extend release-profile with fast-math
endif()

find_package(OpenMP)
if (OPENMP_FOUND)
    set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${OpenMP_CXX_FLAGS}")
endif()

cuda_add_library(ACMP
    src/ACMP.h
    src/ACMP.cpp
    src/ACMP.cu
    )

add_executable(main_depth_estimation
    exe/main_depth_estimation.cpp
    src/colmap_interface/colmap_interface.cpp
    )

target_link_libraries(main_depth_estimation
    ACMP
    ${OpenCV_LIBS}
    ${GFLAGS_LIBRARIES}
    ${GLOG_LIBRARIES}
    threadpool_lib
    )

add_executable(main_depth_fusion
    exe/main_depth_fusion.cpp
    src/colmap_interface/colmap_interface.cpp
    )

target_link_libraries(main_depth_fusion
    ${OpenCV_LIBS}
    ${GFLAGS_LIBRARIES}
    ${GLOG_LIBRARIES}
    )


add_executable(fusion_dev
    exe/main.cpp
    src/colmap_interface/colmap_interface.cpp
    src/colmap_interface/fusion.cpp
    )

target_link_libraries(fusion_dev
    ${OpenCV_LIBS}
    ${GFLAGS_LIBRARIES}
    ${GLOG_LIBRARIES}
    )