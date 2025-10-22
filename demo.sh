# 去畸变
colmap image_undistorter \
    --image_path /ws/18_nfs/zwl/Data/DJI/5w+near/410_gs/images \
    --input_path /ws/18_nfs/zwl/Data/DJI/5w+near/410_gs/colmap_colmap.spatial_spatial_30_map/align \
    --output_path /ws/18_nfs/zwl/Data/DJI/5w+near/410_gs/colmap_colmap.spatial_spatial_30_map/acmp_4gpu \
    --output_type COLMAP \
    --max_image_size 1000

# 运行ACMP
cd build
./main_depth_estimation /ws/18_nfs/zwl/Data/DJI/5w+near/410_gs/colmap_colmap.spatial_spatial_30_map/acmp_4gpu
# ./main_depth_fusion /ws/18_nfs/zwl/Data/DJI/5w+near/410_gs/colmap_colmap.spatial_spatial_30_map/acmh
# ./fusion_dev /ws/18_nfs/zwl/Data/DJI/5w+near/410_gs/colmap_colmap.spatial_spatial_30_map/acmp

# 运行colmap点云融合
colmap stereo_fusion \
    --workspace_path /ws/18_nfs/zwl/Data/DJI/5w+near/410_gs/colmap_colmap.spatial_spatial_30_map/acmp_4gpu \
    --output_path /ws/18_nfs/zwl/Data/DJI/5w+near/410_gs/colmap_colmap.spatial_spatial_30_map/acmp_4gpu/fused.ply \
    --input_type photometric

# 运行OpenMVS的mesh和texture(需配置mesh_texture.py中路径)
python mesh_texture.py