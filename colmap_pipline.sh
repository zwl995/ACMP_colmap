#!/bin/bash

# 设置时间格式
echo "开始COLMAP处理流程: $(date)"

# 第一步
echo "=== 开始第一步: image_undistorter ==="
start1=$(date +%s.%N)

colmap image_undistorter \
    --image_path "/ws/18_nfs/zwl/Data/DJI/5w+near/410_gs/images" \
    --input_path "/ws/18_nfs/zwl/Data/DJI/5w+near/410_gs/colmap_colmap.spatial_spatial_30_map/align" \
    --output_path "/ws/18_nfs/zwl/Data/DJI/5w+near/410_gs/colmap_colmap.spatial_spatial_30_map/dense" \
    --max_image_size 1000

end1=$(date +%s.%N)
time1=$(echo "$end1 - $start1" | bc)
echo "第一步完成: $(date)"
echo "第一步耗时: $time1 秒"

# 第二步
echo "=== 开始第二步: patch_match_stereo ==="
start2=$(date +%s.%N)

colmap patch_match_stereo \
    --workspace_path "/ws/18_nfs/zwl/Data/DJI/5w+near/410_gs/colmap_colmap.spatial_spatial_30_map/dense" \
    --PatchMatchStereo.gpu_index "0,1,2,3" \
    --PatchMatchStereo.num_iterations 3 \
    --PatchMatchStereo.geom_consistency false

end2=$(date +%s.%N)
time2=$(echo "$end2 - $start2" | bc)
total_time=$(echo "$end2 - $start1" | bc)

echo "第二步完成: $(date)"
echo "======================================"
printf "第一步耗时: %.2f 秒\n" $time1
printf "第二步耗时: %.2f 秒\n" $time2
printf "总耗时: %.2f 秒\n" $total_time
echo "======================================"