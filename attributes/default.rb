include_attribute "conda"
include_attribute "kagent"

default["tensorflow"]["version"]                 = "2.9.1"
default['tensorflow']['serving']['version']      = "2.9.0"

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
default['nvidia']['driver_version']      = "515.48.07"
default['nvidia']['driver_url']          = "#{node['download_url']}/NVIDIA-Linux-x86_64-#{node['nvidia']['driver_version']}.run"

# Feature Store example notebooks and datasets
#
default['featurestore']['examples_version']           = node['install']['version']
default['featurestore']['hops_featurestore_demo_dir'] = "featurestore_demo"
default['featurestore']['hops_featurestore_demo_url'] = "#{node['download_url']}/featurestore/#{node['featurestore']['examples_version']}/featurestore.tar.gz"
