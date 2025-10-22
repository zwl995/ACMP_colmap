#ifndef STEREO_FUSION_H
#define STEREO_FUSION_H

#include <vector>
#include <unordered_map>
#include <string>
#include <opencv2/opencv.hpp>
#include "colmap_interface/colmap_interface.h"
#include "colmap_interface/endian.h"

class StereoFusion {
public:
    StereoFusion(const Model& model, bool geom_consistency);
    void Run();
    
    // 结果获取接口
    const std::vector<PointList>& GetPointCloud() const { return point_cloud_; }
    const std::vector<std::vector<int>>& GetPointsVisibility() const { return fused_points_visibility_; }

private:
    const Model& model_;
    const bool geom_consistency_;
    
    std::unordered_map<int, cv::Mat> images_;
    std::unordered_map<int, Camera> cameras_;
    std::unordered_map<int, cv::Mat_<float>> depths_;
    std::unordered_map<int, cv::Mat_<cv::Vec3f>> normals_;
    std::unordered_map<int, cv::Mat> masks_;
    std::vector<PointList> point_cloud_;
    std::vector<std::vector<int>> fused_points_visibility_;

    // 数据处理函数
    void LoadData();
    void ProcessImages();
    void SaveResults();
    
    // 辅助函数
    void RescaleImageAndCamera(cv::Mat_<cv::Vec3b> &src, cv::Mat_<cv::Vec3b> &dst, 
                               cv::Mat_<float> &depth, Camera &camera);
    float3 Get3DPointonWorld(int x, int y, float depth, const Camera& camera);
    void ProjectonCamera(const float3& PointX, const Camera& camera, 
                         float2 &point, float &depth);
    float GetAngle(const cv::Vec3f &v1, const cv::Vec3f &v2);
    cv::Vec3f TransformNormal(const Camera& camera, const cv::Vec3f& normal_local);
    
    // 几何一致性检查
    bool IsValidProjection(int x, int y, const cv::Mat_<float>& depthmap, const cv::Mat& mask);
    bool IsConsistent(const float3& point, 
                     const Camera& ref_cam, float ref_depth, const cv::Vec3f& ref_normal,
                     const Camera& src_cam, float src_depth, const cv::Vec3f& src_normal,
                     int ref_x, int ref_y);
    
    // 输出函数
    void StoreColorPlyFileBinaryPointCloud(const std::string &plyFilePath, 
                                          const std::vector<PointList> &pc);
    void WritePointsVisibility(const std::string& path, 
                              const std::vector<std::vector<int>>& points_visibility);
};

#endif // STEREO_FUSION_H