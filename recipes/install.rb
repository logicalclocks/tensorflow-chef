# First, find out the compute capability of your GPU here: https://developer.nvidia.com/cuda-gpus
# E.g., 
# NVIDIA TITAN X	6.1
# GeForce GTX 1080	6.1
# GeForce GTX 970	5.2
#

if node["cuda"]["accept_nvidia_download_terms"].eql? "true"
  node.override.tensorflow.need_cuda = 1
end
#
# If either 'infinband' or 'mpi' are selected, we have to build tensorflow from source.
#
if node["tensorflow"]["mpi"].eql? "true"
  node.override.tensorflow.need_mpi = 1
  node.override.tensorflow.install = "src"
end

if node["tensorflow"]["mkl"].eql? "true"
  node.override.tensorflow.need_mkl = 1
  node.override.tensorflow.install = "src"
end

if node["tensorflow"]["infiniband"].eql? "true"
  node.override.tensorflow.need_infiniband = 1
  node.override.tensorflow.install = "src"
  if node.platform_family.eql? "debian"
    package "libibverbs-dev"
  else # "rhel"
    package "libibverbs-devel"
  end
end


group node.tensorflow.group do
  action :create
  not_if "getent group #{node.tensorflow.group}"
end

user node.tensorflow.user do
  action :create
  gid node.tensorflow.group
  supports :manage_home => true
  home "/home/#{node.tensorflow.user}"
  shell "/bin/bash"
  not_if "getent passwd #{node.tensorflow.user}"
end

group node.tensorflow.group do
  action :modify
  members ["#{node.tensorflow.user}"]
  append true
  not_if "getent passwd #{node.tensorflow.user}"
end

package "expect" do
  action :install
end

# http://www.pyimagesearch.com/2016/07/04/how-to-install-cuda-toolkit-and-cudnn-for-deep-learning/
case node.platform_family
when "debian"

  execute 'apt-get update -y'

  packages = %w{pkg-config zip g++ zlib1g-dev unzip swig git build-essential cmake unzip libopenblas-dev liblapack-dev linux-image-generic linux-image-extra-virtual linux-source linux-headers-generic python python-numpy python-dev python-pip python-lxml python-pillow libcupti-dev libcurl3-dev}
  for script in packages do
    package script do
      action :install
    end
  end

when "rhel"

  bash "pip-prepare-yum-epel-release-add" do
    user "root"
    code <<-EOF
    set -e
    yum install epel-release -y
    yum install python-pip -y
EOF
  end

  package "gcc" do
    action :install
  end
  package "gcc-c++" do
    action :install
  end
  package "kernel-devel" do
    action :install
  end
  package "openssl" do
    action :install
  end
  package "openssl-devel" do
    action :install
  end
  package "openssl-libs" do
    action :install
  end
  package "python" do 
    action :install
  end
  package "python-devel" do 
    action :install
  end
  package "python-lxml" do 
    action :install
  end
  package "python" do
    action :install
  end
  package "python-pillow" do
    action :install
  end
  #  package "libcupti-dev" do
  #    action :install    
  #  end
  package "libcurl-devel" do
    action :install    
  end
end

bash "pip-upgrade" do
    user "root"
    code <<-EOF
    set -e
    pip install --upgrade pip --user

    EOF
end

bash "pip-yarntf" do
  user "root"
  code <<-EOF
    set -e
    pip install yarntf --user
    EOF
end


# On ec2 you need to disable the nouveau driver and reboot the machine
# http://www.pyimagesearch.com/2016/07/04/how-to-install-cuda-toolkit-and-cudnn-for-deep-learning/
#
template "/etc/modprobe.d/blacklist-nouveau.conf" do
  source "blacklist-nouveau.conf.erb"
  owner "root"
  mode 0775
end

tensorflow_compile "initram" do
  action :kernel_initramfs
end

# echo options nouveau modeset=0 | sudo tee -a /etc/modprobe.d/nouveau-kms.conf
# sudo update-initramfs -u
# sudo reboot



node.default.java.jdk_version = 8
node.default.java.set_etc_environment = true
node.default.java.oracle.accept_oracle_download_terms = true
include_recipe "java::oracle"

if node.tensorflow.install == "src"

  case node["platform_family"]
  when "debian"
    bash "bazel-install" do
      user "root"
      code <<-EOF
      set -e
      echo "deb [arch=amd64] http://storage.googleapis.com/bazel-apt stable jdk1.8" | sudo tee /etc/apt/sources.list.d/bazel.list  
      curl https://bazel.build/bazel-release.pub.gpg | sudo apt-key add 
      apt-get update -y
      sudo apt-get install bazel -y
    EOF
    end
  
  when "rhel"

    # https://gist.github.com/jarutis/6c2934705298720ff92a1c10f6a009d4
    bash "bazel-install-centos" do
      user "root"
      code <<-EOF
      set -e
      yum -y install gcc gcc-c++ kernel-devel make automake autoconf swig git unzip libtool binutils
      yum -y install epel-release
      yum -y install numpy python-devel python-pip
      yum -y install freetype-devel libpng12-devel zip zlib-devel giflib-devel zeromq3-devel
      pip install grpcio_tools mock
      cd #{Chef::Config[:file_cache_path]}
      wget https://github.com/bazelbuild/bazel/releases/download/0.5.2/bazel-0.5.2-installer-linux-x86_64.sh
      chmod +x bazel-*
      ./bazel-0.5.2-installer-linux-x86_64.sh
      /usr/local/bin/bazel
    EOF
    end

    
  end  

end     

#
#
# HDFS support in tensorflow
# https://github.com/tensorflow/tensorflow/issues/2218
#
magic_shell_environment 'HADOOP_HDFS_HOME' do
  value "#{node.hops.base_dir}"
end

magic_shell_environment 'LD_LIBRARY_PATH' do
  value "$LD_LIBRARY_PATH:$JAVA_HOME/jre/lib/amd64/server::/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64"
end

magic_shell_environment 'PATH' do
  value "$PATH:/usr/local/bin"
end

magic_shell_environment 'CUDA_HOME' do
  value "/usr/local/cuda"
end


if node.tensorflow.mpi == "true"
  case node.platform_family
  when "debian"

    package "openmpi-bin" do
    end

    package "libopenmpi-dev" do
    end

    package "mpi-default-bin" do
    end

    bash "compile_openmpi" do
      user "root"
      code <<-EOF
        set -e
        mkdir -p #{node["tensorflow"]["dir"]}/openmpi-2.1.1
        cd /tmp
        wget https://www.open-mpi.org/software/ompi/v2.1/downloads/openmpi-2.1.1.tar.gz
        tar zxf openmpi-2.1.1.tar.gz 
        cd openmpi-2.1.1
        ./configure --prefix=#{node["tensorflow"]["dir"]}/openmpi-2.1.1
        make all install
        chown -R #{node["tensorflow"]["user"]} #{node["tensorflow"]["dir"]}/openmpi-2.1.1
      EOF
      not_if { ::File.directory?("#{node['tensorflow']['dir']}/openmpi-2.1.1") }
    end

  when "rhel"
    # https://wiki.fysik.dtu.dk/niflheim/OmniPath#openmpi-configuration

    
    bash "compile_openmpi" do
      user "root"
      code <<-EOF
        set -e
        cd /tmp
        wget https://www.open-mpi.org/software/ompi/v2.1/downloads/openmpi-2.1.1.tar.gz
        tar zxf openmpi-2.1.1.tar.gz 
        cd openmpi-2.1.1
        ./configure --prefix=#{node["tensorflow"]["dir"]} --with-openib-libdir= --with-openib= 
        make all install
      EOF
    end

  end
end


if node.cuda.enabled == "true"



  raise if "#{node.cuda.accept_nvidia_download_terms}" == "false"
  
  # Check to see if i can find a cuda card. If not, fail with an error

  bash "test_nvidia" do
    user "root"
    code <<-EOF
    set -e
    lspci | grep -i nvidia
  EOF
    not_if { node["cuda"]["skip_test"] == "true" }
  end

  cuda =  File.basename(node.cuda.url)
  base_cuda_dir =  File.basename(cuda, "_linux-run")
  cuda_dir = "/tmp/#{base_cuda_dir}"
  cached_file = "#{Chef::Config[:file_cache_path]}/#{cuda}"


  remote_file cached_file do
    source node.cuda.url
    mode 0755
    action :create
    retries 2
    ignore_failure true
    not_if { File.exist?(cached_file) }
  end

  remote_file cached_file do
    source node.cuda.url_backup
    mode 0755
    action :create
    retries 2
    not_if { File.exist?(cached_file) }
  end

  tensorflow_install "cuda_install" do
    action :cuda
  end


  #    cd #{cuda_dir}
  #    ./NVIDIA-Linux-x86_64-352.39.run
  #    modprobe nvidia
  #    ./cuda-linux64-rel-#{node.cuda.version}-19867135.run
  #    ./cuda-samples-linux-#{node.cuda.version}-19867135.run


  magic_shell_environment 'PATH' do
    value "$PATH:#{node.cuda.base_dir}/bin"
  end

  magic_shell_environment 'LD_LIBRARY_PATH' do
    value "#{node.cuda.base_dir}/lib64:$LD_LIBRARY_PATH"
  end

  magic_shell_environment 'CUDA_HOME' do
    value node.cuda.base_dir
  end


  tensorflow_compile "cuda" do
    action :cuda
  end

  base_cudnn_file =  File.basename(node.cudnn.url)
  cached_cudnn_file = "#{Chef::Config[:file_cache_path]}/#{base_cudnn_file}"

  remote_file cached_cudnn_file do
    source node.cudnn.url
    mode 0755
    action :create
    retries 2
    not_if { File.exist?(cached_cudnn_file) }
  end


  tensorflow_install "cudnn_install" do
    action :cudnn
  end


  tensorflow_compile "cdnn" do
    action :cudnn
  end

  tensorflow_install "gpu_install" do
    action :gpu
  end

else
  tensorflow_install "cpu_install" do
    action :cpu
  end
end

if node.tensorflow.install == "src"

  tensorflow_compile "tensorflow" do
    action :tf
  end

end

