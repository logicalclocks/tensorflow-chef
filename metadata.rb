name             "tensorflow"
maintainer       "Jim Dowling"
maintainer_email "jdowling@kth.se"
license          "Apache v2.0"
description      'Installs/Configures/Runs tensorflow'
version          "1.3.0"

recipe            "tensorflow::install", "Download and compile and install tensorflow"
recipe            "tensorflow::default",  "Setup tensorflow"
recipe            "tensorflow::serving",  "Install tensorflow serving"
recipe            "tensorflow::purge",  "Uninstall tensorflow and cuda"


depends "kagent"
depends "java"
depends "magic_shell"
depends "ndb"
depends "hops"

%w{ ubuntu debian rhel centos }.each do |os|
  supports os
end


attribute "tensorflow/user",
          :description => "user parameter value",
          :type => "string"

attribute "tensorflow/group",
          :description => "group parameter value",
          :type => "string"

attribute "tensorflow/dir",
          :description => "Base installation directory",
          :type => "string"

attribute "download_url",
          :description => "url for binaries",
          :type => "string"

attribute "tensorflow/git_url",
          :description => "url for git sourcecode for tensorflow",
          :type => "string"

attribute "tensorflow/install",
          :description => "'src' to compile/install from source code. 'dist' to install from binaries. ",
          :type => "string"

attribute "tensorflow/mpi",
          :description => "'true' to install openmpi support, 'false' (default) for no MPI support. ",
          :type => "string"

attribute "tensorflow/mkl",
          :description => "'true' to install Intel MKL support, 'false' (default) for no support. ",
          :type => "string"

attribute "tensorflow/rdma",
          :description => "Used by TensorflowOnSpark. 'true' to install rdma (infiniband) support, 'false' (default) for no rdma support. ",
          :type => "string"

attribute "tensorflow/tensorrt",
          :description => "TensorRT is used to optimize trained models and Needs GPU support and Cuda",
          :type => "string"

attribute "tensorflow/custom_url",
          :description => "User-supplied URL for the tensorflow .whl binaries to be installed.",
          :type => "string"

attribute "install/dir",
          :description => "Set to a base directory under which we will install.",
          :type => "string"

attribute "install/user",
          :description => "User to install the services as",
          :type => "string"

#
# Nvidia
#

attribute "nvidia/driver_version",
          :description => "NVIDIA driver version to use",
          :type => "string"

attribute "cuda/accept_nvidia_download_terms",
          :description => "Accept cuda licensing terms and conditions. Default: 'false'. Change to 'true' to enable cuda.",
          :type => "string"

attribute "cuda/skip_test",
          :description => "Dont check if there is a local nvidia card on this machine",
          :type => "string"

attribute "cuda/skip_stop_xserver",
          :description => "Dont restart the xserver (probably a localhost installation)",
          :type => "string"

#
# AMD - ROCM
#
attribute "rocm/install",
          :description => "Set to 'true' to Install the AMD ROCm framework",
          :type => "string"
attribute "rocm/version",
          :description => "Version of ROCm to install",
          :type => "string"
attribute "rocm/dist",
          :description => "Distribution of ROCm to install",
          :type => "string"
attribute "miopen-hip/version",
          :description => "Version of miopen-hip to install",
          :type => "string"
attribute "cxlactivitylogger/version",
          :description => "Version of cxlactivitylogger to install",
          :type => "string"

#
# Jupyter
#
attribute "jupyter/sparkmagic/version",
          :description => "Version of sparkmagic for Jupyter to install. ",
          :type => 'string'
#
# Feature Store examples
#
attribute "featurestore/examples_version",
          :description => "Version of feature store tour artifacts.",
          :type => 'string'

attribute "featurestore/hops_featurestore_demo_dir",
          :description => "Directory to put feature store tour artifacts",
          :type => 'string'

attribute "featurestore/hops_featurestore_demo_url",
          :description => "URL to download featurestore tour artifacts",
          :type => 'string'

#
# Deep Learning examples
#
attribute "tensorflow/examples_version",
          :description => "Version of deep learning tour artifacts.",
          :type => 'string'

attribute "tensorflow/hopstfdemo_dir",
          :description => "Directory to put deep learning tour artifacts",
          :type => 'string'

attribute "tensorflow/hopstfdemo_url",
          :description => "URL to download deep learning tour artifacts",
          :type => 'string'

#
#
# Python library versions
#
#
attribute "tensorflow/version",
          :description => "tensorflow and tensorflow-gpu version to install in python base environments",
          :type => "string"

attribute "tensorflow/rocm/version",
          :description => "tensorflow-rocm version to install in python base environments",
          :type => "string"

attribute "torch/version",
          :description => "PyTorch version to install in python base environments",
          :type => "string"

attribute "torchvision/version",
          :description => "Torchvision version to install in python base environments",
          :type => "string"

attribute "matplotlib/python2/version",
          :description => "Python 2 matplotlib version to install in python base environments",
          :type => "string"


