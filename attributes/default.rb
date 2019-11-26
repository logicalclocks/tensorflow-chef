include_attribute "conda"
include_attribute "kagent"

default['tensorflow']['user']          = node['tensorflow'].attribute?('user') ? node['install']['user'] : node['kagent']['user']
default['tensorflow']['group']         = node['install']['user'].empty? ? node['kagent']['group'] : node['install']['user']

# tensorflow and tensorflow-gpu version
default["tensorflow"]["version"]                 = "1.14.0"

# tensorflow-rocm version
default['tensorflow']['rocm']['version']         = "1.14.0"

default["tensorflow"]['serving']["version"]      = "1.14.0"
default["cudatoolkit"]["version"]                = "10.0"
default["pytorch"]["version"]                    = "1.3.1"
default["pytorch"]["python2"]["build"]           = "py2.7_cuda10.0.130_cudnn7.6.3_0"
#pytorch-1.3.1-py3.6_cpu_0
default["pytorch"]["python3"]["build"]           = "py3.6_cuda10.0.130_cudnn7.6.3_0"
default["torchvision"]["version"]                = "0.4.2"
default["matplotlib"]['python2']["version"]      = "2.2.3"
default["numpy"]["version"]                      = "1.16.5"

#Beam/TFX
default['pyspark']['version']                    = "2.4.3"
default['tfx']['version']                        = "0.14.0"

default['tensorflow']['install']       = "dist" # or 'src' or 'custom'

# tensorflow-1.2.1-debian-gcc_version-python_version.whl
# #{node['download_url']}/tensorflow-#{node['tensorflow']['version']}-#{node['platform']}-5.4-2.7.whl"
default['tensorflow']['custom_url']    = ""

default['tensorflow']['git_url']       = "https://github.com/tensorflow/tensorflow"

#
# TensorFlow/PyTorch example notebooks and datasets
#
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
default['cuda']['versions']            = "9.0.176_384.81~2,10.0.130_410.48~1"
default['cuda']['base_url']            = "#{node['download_url']}/cuda"

default['cuda']['base_dir']                 = "/usr/local"

default['cuda']['accept_nvidia_download_terms']        = "false"
default['cuda']['skip_test']           = "false"
default['cuda']['skip_stop_xserver']   = "false"

# Nvidia driver
default['nvidia']['driver_version']      = "430.26"
default['nvidia']['driver_url']          = "#{node['download_url']}/NVIDIA-Linux-x86_64-#{node['nvidia']['driver_version']}.run"

# Each cudnn version is compiled for a specific cuda version
# Comma separated list of mappings between cuda versions and cudnn versions

# EXAMPLE: cuda version 9.0 cudnn version 7 will be written with 7+9.0
# which will download a file named cudnn-9.0-linux-x64-v7.tgz
default['cudnn']['version_mapping']         = "7+9.0,7.3.0+9.0,7.6.0.64+10.0"
default['cudnn']['base_url']                = "#{node['download_url']}/cudnn"

# As for nccl comma separated list of mapping nccl version + cuda version
default['nccl']['version_mapping']          = "2.2.13-1+9.0,2.3.5-2+10.0"
default['nccl']['base_url']         = "#{node['download_url']}/nccl"

# TensorRT - Nvidia (ubuntu only)
# TensorRT-3.0.4.Ubuntu-16.04.3.x86_64.cuda-9.0.cudnn7.0.tar.gz
default['cuda']['tensorrt']            = "3.0.4"
default['cuda']['tensorrt_version']    = "TensorRT-#{node['cuda']['tensorrt']}.Ubuntu-16.04.3.x86_64-gnu.cuda-9.0.cudnn7.0.tar.gz"

#
# AMD - ROCm dist found at http://repo.radeon.com/rocm/
#
default['rocm']['install']               = "false"

#
# ROCm package versions
#
default['rocm']['debian']['version']               = "2.6.22"
default['miopen-hip']['debian']['version']         = "2.0.0-7a8f787"
default['cxlactivitylogger']['debian']['version']  = "5.6.7259"
default['rocm']['rhel']['version']               = "2.6.22-1"
default['miopen-hip']['rhel']['version']         = "2.0.0_7a8f7878-1"
default['cxlactivitylogger']['rhel']['version']  = "5.6.7259-gf50cd35"

# ROCm dist found at http://repo.radeon.com/rocm/
default['rocm']['dist']['rhel']          = "#{node['download_url']}/rocm/rhel/rocm_#{node['rocm']['rhel']['version']}.tar.gz"
default['rocm']['dist']['debian']        = "#{node['download_url']}/rocm/debian/rocm_#{node['rocm']['debian']['version']}.tar.gz"

#
# ROCm directory where to put ROCm distribution
#
default['rocm']['dir']           = node['install']['dir'].empty? ? "/srv/hops" : node['install']['dir']
default['rocm']['base_dir']      = node['rocm']['dir'] + "/rocm"

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

default['openmpi']['version']          = "openmpi-3.1.0.tar.gz"


default['jupyter']['sparkmagic']['version']            = "0.12.7"
default['jupyter']['sparkmagic']['url']                = node['download_url'] + "/sparkmagic-" + node['jupyter']['sparkmagic']['version'] + ".tar.gz"

# Pinned Python libary versions to install in the base environments
default['python2']['ipykernel_version']                = "4.10.0"
default['python2']['jupyter_console_version']          = "5.2.0"
default['python2']['ipython_version']                  = "5.8.0"


# Feature Store example notebooks and datasets
#
default['featurestore']['examples_version']           = node['install']['version']
default['featurestore']['hops_featurestore_demo_dir'] = "featurestore_demo"
default['featurestore']['hops_featurestore_demo_url'] = "#{node['download_url']}/featurestore/#{node['featurestore']['examples_version']}/featurestore.tar.gz"


# Maggy - dist optimization for TensorFlow/Spark
#
default['maggy']['version']                           = "0.3.0"
