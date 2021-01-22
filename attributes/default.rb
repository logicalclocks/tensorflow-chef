include_attribute "conda"
include_attribute "kagent"

default["tensorflow"]["version"]                 = "2.4.1"
default['tensorflow']['serving']['version']      = "2.4.0"

#
# TensorFlow/PyTorch example notebooks and datasets
#
default['tensorflow']['examples_version']  = node['install']['version']
default['tensorflow']['hopstfdemo_dir'] = "tensorflow_demo"
default['tensorflow']['hopstfdemo_url'] = "#{node['download_url']}/tensorflow/#{node['tensorflow']['examples_version']}/demo.tar.gz"

default['cuda']['accept_nvidia_download_terms']        = "false"
default['cuda']['skip_test']           = "false"
default['cuda']['skip_stop_xserver']   = "false"

# Nvidia driver
default['nvidia']['driver_version']      = "440.95.01"
default['nvidia']['driver_url']          = "#{node['download_url']}/NVIDIA-Linux-x86_64-#{node['nvidia']['driver_version']}.run"
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

# Feature Store example notebooks and datasets
#
default['featurestore']['examples_version']           = node['install']['version']
default['featurestore']['hops_featurestore_demo_dir'] = "featurestore_demo"
default['featurestore']['hops_featurestore_demo_url'] = "#{node['download_url']}/featurestore/#{node['featurestore']['examples_version']}/featurestore.tar.gz"
