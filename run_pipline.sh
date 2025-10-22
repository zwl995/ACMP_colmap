#!/bin/bash

# ============================================================================
# 配置区域 - 只需修改这里的路径即可
# ============================================================================

# 基础路径配置
BASE_DIR="/ws/18_nfs/zwl/Data/DJI/5w+near/410_gs"
IMAGE_DIR="${BASE_DIR}/images"
COLMAP_DIR="${BASE_DIR}/colmap_colmap.spatial_spatial_30_map"
ALIGN_DIR="${COLMAP_DIR}/align"
ACMP_OUTPUT="${COLMAP_DIR}/acmp_4gpu"
FUSED_PLY="${ACMP_OUTPUT}/fused.ply"

# 其他参数
MAX_IMAGE_SIZE=1000
LOG_FILE="process.log"

# ============================================================================
# 脚本主体 - 依次执行各步骤
# ============================================================================

echo "开始执行时间: $(date)" > $LOG_FILE
echo "路径配置:" >> $LOG_FILE
echo "  基础路径: ${BASE_DIR}" >> $LOG_FILE
echo "  图像路径: ${IMAGE_DIR}" >> $LOG_FILE
echo "  输出路径: ${ACMP_OUTPUT}" >> $LOG_FILE
echo "==============================================" >> $LOG_FILE

total_start=$(date +%s)

# 步骤1: 去畸变 (依赖: 原始图像和align结果)
echo "步骤1: 去畸变" >> $LOG_FILE
echo "开始时间: $(date)" >> $LOG_FILE
echo "命令: colmap image_undistorter --image_path ${IMAGE_DIR} --input_path ${ALIGN_DIR} --output_path ${ACMP_OUTPUT} --output_type COLMAP --max_image_size ${MAX_IMAGE_SIZE}" >> $LOG_FILE

step1_start=$(date +%s)
colmap image_undistorter \
    --image_path ${IMAGE_DIR} \
    --input_path ${ALIGN_DIR} \
    --output_path ${ACMP_OUTPUT} \
    --output_type COLMAP \
    --max_image_size ${MAX_IMAGE_SIZE}
step1_end=$(date +%s)
step1_duration=$((step1_end - step1_start))

echo "结束时间: $(date)" >> $LOG_FILE
echo "耗时: ${step1_duration} 秒" >> $LOG_FILE
echo "----------------------------------------------" >> $LOG_FILE

# 检查步骤1是否成功
if [ $? -ne 0 ]; then
    echo "错误: 去畸变步骤失败!" >> $LOG_FILE
    exit 1
fi

# 步骤2: ACMP深度估计 (依赖: 去畸变结果)
echo "步骤2: ACMP深度估计" >> $LOG_FILE
echo "开始时间: $(date)" >> $LOG_FILE
echo "命令: cd build && ./main_depth_estimation ${ACMP_OUTPUT}" >> $LOG_FILE

step2_start=$(date +%s)
cd build && ./main_depth_estimation ${ACMP_OUTPUT}
step2_end=$(date +%s)
step2_duration=$((step2_end - step2_start))

echo "结束时间: $(date)" >> $LOG_FILE
echo "耗时: ${step2_duration} 秒" >> $LOG_FILE
echo "----------------------------------------------" >> $LOG_FILE

# 检查步骤2是否成功
if [ $? -ne 0 ]; then
    echo "错误: ACMP深度估计步骤失败!" >> $LOG_FILE
    exit 1
fi

# 返回原始目录（如果ACMP步骤改变了目录）
cd - > /dev/null

# 步骤3: COLMAP点云融合 (依赖: ACMP深度估计结果)
echo "步骤3: COLMAP点云融合" >> $LOG_FILE
echo "开始时间: $(date)" >> $LOG_FILE
echo "命令: colmap stereo_fusion --workspace_path ${ACMP_OUTPUT} --output_path ${FUSED_PLY} --input_type photometric" >> $LOG_FILE

step3_start=$(date +%s)
colmap stereo_fusion \
    --workspace_path ${ACMP_OUTPUT} \
    --output_path ${FUSED_PLY} \
    --input_type photometric
step3_end=$(date +%s)
step3_duration=$((step3_end - step3_start))

echo "结束时间: $(date)" >> $LOG_FILE
echo "耗时: ${step3_duration} 秒" >> $LOG_FILE
echo "----------------------------------------------" >> $LOG_FILE

# 检查步骤3是否成功
if [ $? -ne 0 ]; then
    echo "错误: COLMAP点云融合步骤失败!" >> $LOG_FILE
    exit 1
fi

# 步骤4: OpenMVS mesh和texture (依赖: 前面的所有结果)
echo "步骤4: OpenMVS mesh和texture" >> $LOG_FILE
echo "开始时间: $(date)" >> $LOG_FILE
echo "命令: python mesh_texture.py" >> $LOG_FILE

step4_start=$(date +%s)
python mesh_texture.py
step4_end=$(date +%s)
step4_duration=$((step4_end - step4_start))

echo "结束时间: $(date)" >> $LOG_FILE
echo "耗时: ${step4_duration} 秒" >> $LOG_FILE
echo "----------------------------------------------" >> $LOG_FILE

# 检查步骤4是否成功
if [ $? -ne 0 ]; then
    echo "错误: OpenMVS mesh和texture步骤失败!" >> $LOG_FILE
    exit 1
fi

total_end=$(date +%s)
total_duration=$((total_end - total_start))

# 输出总结
echo "==============================================" >> $LOG_FILE
echo "所有命令执行完成!" >> $LOG_FILE
echo "总开始时间: $(date -d @${total_start})" >> $LOG_FILE
echo "总结束时间: $(date -d @${total_end})" >> $LOG_FILE
echo "总耗时: ${total_duration} 秒 ($((${total_duration}/60)) 分钟)" >> $LOG_FILE
echo "" >> $LOG_FILE

# 生成详细的耗时报告
echo "各步骤耗时统计:" >> $LOG_FILE
echo "----------------------------------------------" >> $LOG_FILE
echo "去畸变: ${step1_duration} 秒" >> $LOG_FILE
echo "ACMP深度估计: ${step2_duration} 秒" >> $LOG_FILE
echo "COLMAP点云融合: ${step3_duration} 秒" >> $LOG_FILE
echo "OpenMVS mesh和texture: ${step4_duration} 秒" >> $LOG_FILE
echo "==============================================" >> $LOG_FILE