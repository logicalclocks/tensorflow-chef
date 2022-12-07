# First, find out the compute capability of your GPU here: https://developer.nvidia.com/cuda-gpus
# E.g.,
# NVIDIA TITAN X	6.1
# GeForce GTX 1080	6.1
# GeForce GTX 970	5.2
#

if node['cuda']['accept_nvidia_download_terms'].eql? "true"
  node.override['tensorflow']['need_cuda'] = 1
end

# http://www.pyimagesearch.com/2016/07/04/how-to-install-cuda-toolkit-and-cudnn-for-deep-learning/
case node['platform_family']
when "debian"

  package ["pkg-config", "zip", "g++", "zlib1g-dev", "unzip", "swig", "git", "build-essential", "cmake", "libopenblas-dev", "liblapack-dev", "linux-image-#{node['kernel']['release']}", "linux-headers-#{node['kernel']['release']}", "libcupti-dev", "libcurl3-dev", "pciutils"] do
    retries 10
    retry_delay 30
  end

when "rhel"
  if node['rhel']['epel'].downcase == "true"
    package 'epel-release' do
      retries 10
      retry_delay 30
    end
  end

  # With our current CentOS box "CentOS Linux release 7.5.1804 (Core)",
  # sudo yum install "kernel-devel-uname-r == $(uname -r)" doesn't work as it cannot find the kernel-devel version
  # returned by uname-r.
  # It works in AWS CentOS Linux release 7.6.1810 (Core) though.
  # We can install the specific version and if that fails, then install the kernel devel package without
  # specifying a version. In our current Centos box bento/centos-7.5 this fails as the kernel-devel package is not
  # available
  package 'kernel-devel' do
    version node['kernel']['release'].sub(/\.#{node['kernel']['machine']}/, "")
    arch node['kernel']['machine']
    action :install
    ignore_failure true
  end

  package 'kernel-devel' do
    retries 10
    retry_delay 30
    action :install
    not_if  "ls -l /usr/src/kernels/$(uname -r)"
  end

  package ['pciutils', 'mlocate', 'gcc', 'gcc-c++', 'openssl', 'openssl-devel', 'libcurl-devel'] do
    retries 10
    retry_delay 30
  end
end

include_recipe "java"

#
# HDFS support in tensorflow
# https://github.com/tensorflow/tensorflow/issues/2218
#
magic_shell_environment 'HADOOP_HDFS_HOME' do
  value "#{node['hops']['base_dir']}"
end


if node['cuda']['accept_nvidia_download_terms'].eql?("true")

  package "clang" do
    retries 10
    retry_delay 30
  end

  # Check to see if i can find a cuda card. If not, fail with an error
  bash "test_nvidia" do
    user "root"
    code <<-EOF
      set -e
      lspci | grep -i nvidia
    EOF
    not_if { node['cuda']['skip_test'] == "true" }
  end

  bash "stop_xserver" do
    user "root"
    ignore_failure true
    code <<-EOF
      service lightdm stop
    EOF
  end

  tensorflow_install "driver_install" do
    driver_version node['nvidia']['driver_version']
    action :driver
  end

  # Test installation
  bash 'test_nvidia_installation' do
    user "root"
    code <<-EOH
      nvidia-smi -L
    EOH
  end
end
