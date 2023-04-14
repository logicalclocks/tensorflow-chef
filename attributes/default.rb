include_attribute "conda"
include_attribute "kagent"

default["tensorflow"]["version"]                 = "2.11.0"
default['tensorflow']['serving']['version']      = "2.11.0"

default['cuda']['accept_nvidia_download_terms']        = "false"
default['cuda']['skip_test']           = "false"
default['cuda']['skip_stop_xserver']   = "false"

# Nvidia driver
default['nvidia']['driver_version']      = "525.85.12"
default['nvidia']['driver_url']          = "#{node['download_url']}/NVIDIA-Linux-x86_64-#{node['nvidia']['driver_version']}.run"
