include_attribute "kagent"

default.tensorflow.group         = node.kagent.user
default.tensorflow.user          = node.kagent.group
default.tensorflow.version       = "0.10.0rc0"


default.cuda.enabled             = "false"

default.cuda.major_version       = "7.5"
default.cuda.minor_version       = "18"
default.cuda.version             = node.cuda.major_version + "." + node.cuda.minor_version
default.cuda.url                 = "#{node.download_url}/cuda_#{node.cuda.version}_linux.run"
default.cuda.url_backup     = "http://developer.download.nvidia.com/compute/cuda/#{node.cuda.major_version}/Prod/local_installers/cuda_#{node.cuda.version}_linux.run"
default.cuda.md5sum              = "4b3bcecf0dfc35928a0898793cf3e4c6"

default.cudnn.major_version            = "4"
default.cudnn.minor_version            = "0"
default.cudnn.version            = node.cudnn.major_version + "." + node.cudnn.minor_version
#default.cudnn.url                = "#{node.download_url}/cudnn-#{node.cuda.major_version}-linux-x64-v#{node.cudnn.version}.tgz"
#cudnn-7.0-linux-x64-v4.0-prod.tgz
default.cudnn.url                = "#{node.download_url}/cudnn-7.0-linux-x64-v#{node.cudnn.version}-prod.tgz"

default.cuda.dir                 = "/usr/local"
default.cuda.base_dir            = "#{cuda.dir}/cuda"
default.cuda.version_dir         = "#{cuda.dir}/cuda-#{node.cuda.major_version}"
