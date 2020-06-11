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

  package ["pkg-config", "zip", "g++", "zlib1g-dev", "unzip", "swig", "git", "build-essential", "cmake", "unzip", "libopenblas-dev", "liblapack-dev", "linux-image-#{node['kernel']['release']}", "linux-headers-#{node['kernel']['release']}", "python2.7", "python2.7-numpy", "python2.7-dev", "python-pip", "python2.7-lxml", "python-pillow", "libcupti-dev", "libcurl3-dev", "python-wheel", "python-six", "pciutils"]

when "rhel"
  if node['rhel']['epel'].downcase == "true"
    package 'epel-release'
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
    action :install
    not_if  "ls -l /usr/src/kernels/$(uname -r)"
  end

  package ['pciutils', 'python-pip', 'mlocate', 'gcc', 'gcc-c++', 'openssl', 'openssl-devel', 'python', 'python-devel', 'python-lxml', 'python-pillow', 'libcurl-devel', 'python-wheel', 'python-six']
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

  package "clang"

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

#
# ROCm
#

if node['rocm']['install'].eql? "true"

  case node['platform_family']
  when "debian"
      install_dir = node['rocm']['dir'] + "/rocm-" + node['rocm']['debian']['version']
      directory node["rocm"]["dir"]  do
        owner "_apt"
        group "root"
        mode "755"
        action :create
        not_if { File.directory?("#{node["rocm"]["dir"]}") }
      end

      directory install_dir do
        owner "_apt"
        group "root"
        mode "750"
        action :create
      end

      link node["rocm"]["base_dir"] do
        owner "_apt"
        group "root"
        to install_dir
      end
  when "rhel"
      install_dir = node['rocm']['dir'] + "/rocm-" + node['rocm']['rhel']['version']
      directory node["rocm"]["dir"]  do
        owner "root"
        group "root"
        mode "755"
        action :create
        not_if { File.directory?("#{node["rocm"]["dir"]}") }
      end

      directory install_dir do
        owner "root"
        group "root"
        mode "750"
        action :create
      end

      link node["rocm"]["base_dir"] do
        owner "root"
        group "root"
        to install_dir
      end
  end

  tensorflow_purge "remove_old_rocm" do
    action :rocm
  end

  tensorflow_amd "install_rocm" do
    action :install_rocm
    rocm_home install_dir
  end
end
