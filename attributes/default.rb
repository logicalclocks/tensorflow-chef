include_attribute "kagent"

default['tensorflow']['user']          = node['tensorflow'].attribute?('user') ? node['install']['user'] : node['kagent']['user']
default['tensorflow']['group']         = node['install']['user'].empty? ? node['kagent']['group'] : node['install']['user']

default["tensorflow"]["version"]       = "1.11.0"

default['tensorflow']['install']       = "dist" # or 'src' or 'custom'

# tensorflow-1.2.1-debian-gcc_version-python_version.whl
# #{node['download_url']}/tensorflow-#{node['tensorflow']['version']}-#{node['platform']}-5.4-2.7.whl"
default['tensorflow']['custom_url']    = ""

default['tensorflow']['git_url']       = "https://github.com/tensorflow/tensorflow"

#
# TensorFlow/PyTorch example notebooks and datasets
#
default['tensorflow']['hopstf_version'] = '0.0.1'
default['tensorflow']['hopstf_url']    = "#{node['download_url']}/tensorflow/hops-tensorflow-#{node['tensorflow']['hopstf_version']}.jar"
default['tensorflow']['examples_version']  = node['install']['version']
default['tensorflow']['hopstfdemo_dir'] = "tensorflow_demo"
default['tensorflow']['hopstfdemo_url'] = "#{node['download_url']}/tensorflow/#{node['tensorflow']['examples_version']}/demo.tar.gz"

#
# Base directories
#
default['tensorflow']['dir']           = node['install']['dir'].empty? ? "/srv/hops" : node['install']['dir']
default['tensorflow']['home']          = node['tensorflow']['dir'] + "/tensorflow-" + node['tensorflow']['version']
default['tensorflow']['base_dir']      = node['tensorflow']['dir'] + "/tensorflow"

# Comma separated list of supported cuda versions (~ # of patches )
default['cuda']['versions']            = "9.0.176_384.81~2"
default['cuda']['base_url']            = "#{node['download_url']}/cuda/"

default['cuda']['base_dir']                 = "/usr/local"

default['cuda']['accept_nvidia_download_terms']        = "false"
default['cuda']['skip_test']           = "false"
default['cuda']['skip_stop_xserver']   = "false"

# Nvidia driver
default['nvidia']['driver_version']      = "390.59"
default['nvidia']['driver_url']          = "#{node['download_url']}/NVIDIA-Linux-x86_64-#{node['nvidia']['driver_version']}.run"

# Each cudnn version is compiled for a specific cuda version
# Comma separated list of mappings between cuda versions and cudnn versions

# EXAMPLE: cuda version 9.0 cudnn version 7 will be written with 7+9.0
# which will download a file named cudnn-9.0-linux-x64-v7.tgz
default['cudnn']['version_mapping']         = "7+9.0,7.3.0+9.0"
default['cudnn']['base_url']                = "#{node['download_url']}/cudnn"

# As for cudnn comma separated list of mapping nccl version + cuda version
default['nccl']['version_mapping']          = "2.2.13-1+9.0"
default['nccl']['base_url']         = "#{node['download_url']}/nccl"

# TensorRT - Nvidia (ubuntu only)
# TensorRT-3.0.4.Ubuntu-16.04.3.x86_64.cuda-9.0.cudnn7.0.tar.gz
default['cuda']['tensorrt']            = "3.0.4"
default['cuda']['tensorrt_version']    = "TensorRT-#{node['cuda']['tensorrt']}.Ubuntu-16.04.3.x86_64-gnu.cuda-9.0.cudnn7.0.tar.gz"

default['tensorflow']['mkl']           = "false"
default['tensorflow']['mpi']           = "false"
default['tensorflow']['rdma']          = "false"
default['tensorflow']['tensorrt']      = "false"


default['tensorflow']['need_cuda']     = 0
default['tensorflow']['need_mpi']      = 0
default['tensorflow']['need_mkl']      = 0
default['tensorflow']['need_rdma']     = 0
default['tensorflow']['need_tensorrt'] = 0

# https://github.com/bazelbuild/bazel/releases/download/0.5.2/bazel-0.5.2-installer-linux-x86_64.sh
default['bazel']['major_version']      = "0.11"
default['bazel']['minor_version']      = "1"
default['bazel']['version']            = node['bazel']['major_version'] + "." + node['bazel']['minor_version']
default['bazel']['url']                = "#{node['download_url']}/bazel-#{node['bazel']['version']}-installer-linux-x86_64.sh"

default['tensorflow']['serving']['version']      = "1.8.0"

default['openmpi']['version']          = "openmpi-3.1.0.tar.gz"
