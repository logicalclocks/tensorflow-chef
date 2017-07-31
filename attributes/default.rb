include_attribute "kagent"

default.tensorflow.user          = node.install.user.empty? ? node.kagent.user : node.install.user
default.tensorflow.group         = node.install.user.empty? ? node.kagent.group : node.install.user
default.tensorflow.base_version  = "1.2.0"
default.tensorflow.version       = node.tensorflow.base_version

default.tensorflow.install       = "dist" # or 'src' or 'custom'

# tensorflow-1.2.1-debian-gcc_version-python_version.whl
default.tensorflow.custom_url    = "#{download_url}/tensorflow-#{node['tensorflow']['version']}-#{node['platform']}-5.4-2.7.whl"

default.tensorflow.git_url       = "https://github.com/tensorflow/tensorflow"
default.tensorflow.python_url    = "http://snurran.sics.se/hops/Python.zip"
default.tensorflow.tfspark_url   = "http://snurran.sics.se/hops/tfspark.zip"
default.tensorflow.hopstf_url    = "http://snurran.sics.se/hops/tensorflow/hops-tensorflow-0.0.1.jar"
default.tensorflow.base_dirname  = "mnist"
default.tensorflow.hopstfdemo_dir = "tensorflow_demo"
default.tensorflow.hopstfdemo_url = "http://snurran.sics.se/hops/tensorflow/#{tensorflow.base_dirname}.tar.gz"

default.tensorflow.dir           = node.install.dir.empty? ? "/srv/hops" : node.install.dir
default.tensorflow.home          = node.tensorflow.dir + "/tensorflow-" + node.tensorflow.version
default.tensorflow.base_dir      = node.kagent.dir + "/tensorflow"


default.tensorflow.mpi           = "false"
default.tensorflow.infiniband    = "false"
default.tensorflow.mkl           = "false"

default.cuda.major_version       = "8.0"
default.cuda.minor_version       = "61"
default.cuda.build_version       = "375.26"
default.cuda.patch_version       = "2"
default.cuda.version             = node.cuda.major_version + "." + node.cuda.minor_version + "_" + node.cuda.build_version
default.cuda.url                 = "#{node.download_url}/cuda_#{node.cuda.version}_linux.run"
default.cuda.url_backup          = "http://developer.download.nvidia.com/compute/cuda/#{node.cuda.major_version}/Prod/local_installers/cuda_#{node.cuda.version}_linux.run"
default.cuda.md5sum              = "33e1bd980e91af4e55f3ef835c103f9b"

default.cuda.version_patch       = node.cuda.major_version + "." + node.cuda.minor_version + "." + node.cuda.patch_version
default.cuda.url_patch           = "#{node.download_url}/cuda_#{node.cuda.version_patch}_linux.run"


default.cudnn.major_version      = "6"
default.cudnn.minor_version      = "0"
default.cudnn.version            = node.cudnn.major_version + "." + node.cudnn.minor_version
default.cudnn.url                = "#{node.download_url}/cudnn-#{node.cuda.major_version}-linux-x64-v#{node.cudnn.version}.tgz"

default.cuda.dir                 = "/usr/local"
default.cuda.base_dir            = "#{cuda.dir}/cuda"
default.cuda.version_dir         = "#{cuda.dir}/cuda-#{node.cuda.major_version}"


default.cuda.accept_nvidia_download_terms        = "false"
default.cuda.enabled             = node["cuda"]["accept_nvidia_download_terms"]
default.cuda.skip_test           = "false"
default["tensorflow"]["mpi"]     = "false"

default.tensorflow.need_cuda     = 0
default.tensorflow.need_mpi      = 0
default.tensorflow.need_mkl      = 0
default.tensorflow.need_infiniband  = 0

# https://github.com/bazelbuild/bazel/releases/download/0.5.2/bazel-0.5.2-installer-linux-x86_64.sh
default.bazel.major_version      = "0.5"
default.bazel.minor_version      = "2"
default.bazel.version            = node.bazel.major_version + "." + node.bazel.minor_version
default.bazel.url                = "#{node.download_url}/bazel-#{node.bazel.version}-installer-linux-x86_64.sh"
