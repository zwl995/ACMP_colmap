import subprocess
from pathlib import Path
openmvs_install = f"/usr/local/bin/OpenMVS"

def do_shell(cmd: str):
    print(cmd)
    p = subprocess.Popen(cmd, shell=True)
    status = p.wait()
    assert status == 0, print(f"[!!!fail !!!] {cmd}")

mvs_path = Path(f"/ws/18_nfs/zwl/Data/DJI/5w+near/410_gs/colmap_colmap.spatial_spatial_30_map/acmp_4gpu_mvs")
workspace_path = Path(f"/ws/18_nfs/zwl/Data/DJI/5w+near/410_gs/colmap_colmap.spatial_spatial_30_map/acmp_4gpu")
scene_num = 1

mvs_path.mkdir(exist_ok=True, parents=True)

if not (mvs_path / "images").exists():
    assert (workspace_path / "images").is_dir()
    (mvs_path / "images").symlink_to((workspace_path / 'images'))

cmd_interface = f"{openmvs_install}/InterfaceCOLMAP -w {mvs_path} -i {workspace_path} -o {mvs_path}/{str(scene_num).zfill(6)}_dense.mvs" \
                +f" --image-folder {mvs_path}/images"
do_shell(cmd_interface)

cmd_reconstruction = f"{openmvs_install}/ReconstructMesh -w {mvs_path} -i {mvs_path}/{str(scene_num).zfill(6)}_dense.mvs"
do_shell(cmd_reconstruction)

cmd_texture = f"{openmvs_install}/TextureMesh -w {mvs_path} -i {mvs_path}/{str(scene_num).zfill(6)}_dense.mvs" \
                        +f" -m {mvs_path}/{str(scene_num).zfill(6)}_dense_mesh.ply"
do_shell(cmd_texture)
