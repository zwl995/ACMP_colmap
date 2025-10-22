#include "colmap_interface/fusion.h"
#include <glog/logging.h>
#include <opencv2/opencv.hpp>

int main(int argc, char** argv) {
    double t_start = cv::getTickCount();

    google::InitGoogleLogging(argv[0]);
    FLAGS_alsologtostderr = true;
    FLAGS_colorlogtostderr = true;
    FLAGS_v = 2;

    if (argc < 2) {
        std::cout << "USAGE: ACMP dense_folder" << std::endl;
        return -1;
    }

    std::string dense_folder = argv[1];
    Model model(dense_folder, "sparse", "stereo/depth_maps", "stereo/normal_maps", "images");
    model.Read();
    model.ReduceMemory();

    StereoFusion fusion(model, false);
    fusion.Run();

    double t_end = cv::getTickCount();
    double t_used = (t_end - t_start) / cv::getTickFrequency() / 60;
    std::cout << "Total time: " << t_used << " min" << std::endl;

    return 0;
}