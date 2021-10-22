#pragma once

#include <unordered_map>
#include <glog/logging.h>

#include "colmap_interface/endian.h"
#include "./types.h"

float3 Get3DPointonRefCam(const int x, const int y, const float depth, const Camera camera);

#define CUDA_SAFE_CALL(error) CudaSafeCall(error, __FILE__, __LINE__)
#define CUDA_CHECK_ERROR() CudaCheckError(__FILE__, __LINE__)

void CudaSafeCall(const cudaError_t error, const std::string& file, const int line);
void CudaCheckError(const char* file, const int line);

struct cudaTextureObjects {
    cudaTextureObject_t images[MAX_IMAGES];
};

struct PatchMatchParams {
    int max_iterations = 3;
    int patch_size = 11;
    int num_images = 5;
    int max_image_size=3200;
    int radius_increment = 2;
    float sigma_spatial = 5.0f;
    float sigma_color = 3.0f;
    int top_k = 4;
    float baseline = 0.54f;
    float depth_min = 0.0f;
    float depth_max = 1.0f;
    float disparity_min = 0.0f;
    float disparity_max = 1.0f;
    // 下面有三个参数会使得程序处在很多中模式下，一般
    // 1. 用平面先验，去掉几何一致
    // 2. 不用平面先验，加上几何一致，但是读入的先验是上一次photometric得到的深度图
    // 3. 不用平面先验，加上几何一致，并且读入的是上一次geometric得到的深度图
    bool geom_consistency = false;
    bool multi_geometry = false; // 如果之前有过使用几何一致性才需要使用这个参数，这个参数会控制预先读入的数据是带几何一致的还是不带。
    bool planar_prior = false;
};

class ACMP {
public:
    ACMP(const std::unordered_map<int, std::string>& _image_id_to_image_name, const std::unordered_map<int, Camera>& _image_id_to_camera, const std::string& _depth_folder, const std::string& _normal_folder, const std::string& _image_folder);
    ~ACMP();

    void InuputInitialization(const std::string &dense_folder, const Problem &problem);
    void Colmap2MVS(const std::string &dense_folder, std::vector<Problem> &problems);
    void CudaSpaceInitialization(const std::string &dense_folder, const Problem &problem);
    void RunPatchMatch();
    void SetGeomConsistencyParams(bool multi_geometry = false);
    void SetPlanarPriorParams();
    int GetReferenceImageWidth();
    int GetReferenceImageHeight();
    cv::Mat GetReferenceImage();
    float4 GetPlaneHypothesis(const int index);
    float GetCost(const int index);
    void GetSupportPoints(std::vector<cv::Point>& support2DPoints);
    std::vector<Triangle> DelaunayTriangulation(const cv::Rect boundRC, const std::vector<cv::Point>& points);
    float4 GetPriorPlaneParams(const Triangle triangle, const cv::Mat_<float> depths);
    float GetDepthFromPlaneParam(const float4 plane_hypothesis, const int x, const int y);
    float GetMinDepth();
    float GetMaxDepth();
    void CudaPlanarPriorInitialization(const std::vector<float4> &PlaneParams, const cv::Mat_<float> &masks);
private:
    int num_images;
    std::vector<cv::Mat> images;
    std::vector<cv::Mat> depths;
    std::vector<Camera> cameras;
    cudaTextureObjects texture_objects_host;
    cudaTextureObjects texture_depths_host;
    float4 *plane_hypotheses_host;
    float *costs_host;
    float4 *prior_planes_host;
    unsigned int *plane_masks_host;
    PatchMatchParams params;

    Camera *cameras_cuda;
    cudaArray *cuArray[MAX_IMAGES];
    cudaArray *cuDepthArray[MAX_IMAGES];
    cudaTextureObjects *texture_objects_cuda;
    cudaTextureObjects *texture_depths_cuda;
    float4 *plane_hypotheses_cuda;
    float *costs_cuda;
    curandState *rand_states_cuda;
    unsigned int *selected_views_cuda;
    float *depths_cuda;
    float4 *prior_planes_cuda;
    unsigned int *plane_masks_cuda;

public:
    const std::unordered_map<int, std::string>& image_id_to_image_name;
    const std::unordered_map<int, Camera>& image_id_to_camera;
    const std::string depth_folder, normal_folder, image_folder;
};
