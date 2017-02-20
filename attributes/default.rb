include_attribute "kagent"

default.tensorflow.user          = node.kagent.user
default.tensorflow.group         = node.kagent.group
#default.tensorflow.base_version  = "0.11.0"
default.tensorflow.base_version  = "1.0.0"
default.tensorflow.version       = node.tensorflow.base_version

default.tensorflow.install       = "dist" # or 'src'

default.tensorflow.git_url       = "https://github.com/tensorflow/tensorflow"

default.tensorflow.dir           = "/srv"
default.tensorflow.home          = node.tensorflow.dir + "/tensorflow-" + node.tensorflow.version
default.tensorflow.base_dir      = node.kagent.dir + "/tensorflow"

default.cuda.major_version       = "8.0"
default.cuda.minor_version       = "44"
default.cuda.version             = node.cuda.major_version + "." + node.cuda.minor_version
default.cuda.url                 = "#{node.download_url}/cuda_#{node.cuda.version}_linux-run"
default.cuda.url_backup          = "http://developer.download.nvidia.com/compute/cuda/#{node.cuda.major_version}/Prod/local_installers/cuda_#{node.cuda.version}_linux-run"
default.cuda.md5sum              = "6dca912f9b7e2b7569b0074a41713640"

default.cudnn.major_version      = "5"
default.cudnn.minor_version      = "1"
default.cudnn.version            = node.cudnn.major_version + "." + node.cudnn.minor_version
default.cudnn.url                = "#{node.download_url}/cudnn-#{node.cuda.major_version}-linux-x64-v#{node.cudnn.version}.tgz"

default.cuda.dir                 = "/usr/local"
default.cuda.base_dir            = "#{cuda.dir}/cuda"
default.cuda.version_dir         = "#{cuda.dir}/cuda-#{node.cuda.major_version}"
default.cuda.accept_nvidia_download_terms        = "false"

default.cuda.enabled             = node.cuda.accept_nvidia_download_terms
