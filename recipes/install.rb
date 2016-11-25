
# First, find out the compute capability of your GPU here: https://developer.nvidia.com/cuda-gpus
# E.g., 
# NVIDIA TITAN X	6.1
# GeForce GTX 1080	6.1
# GeForce GTX 970	5.2
#

group node.tensorflow.group do
  action :create
  not_if "getent group #{node.tensorflow.group}"
end


user node.tensorflow.user do
  action :create
  supports :manage_home => true
  home "/home/#{node.tensorflow.user}"
  shell "/bin/bash"
  not_if "getent passwd #{node.tensorflow.user}"
end

group node.tensorflow.group do
  action :modify
  members ["#{node.tensorflow.user}"]
  append true
end

package "expect" do
 action :install
end

# http://www.pyimagesearch.com/2016/07/04/how-to-install-cuda-toolkit-and-cudnn-for-deep-learning/
case node.platform_family
when "debian"

execute 'apt-get update -y'

  packages = %w{pkg-config zip g++ zlib1g-dev unzip swig git build-essential cmake unzip libopenblas-dev liblapack-dev linux-image-generic linux-image-extra-virtual linux-source linux-headers-generic python python-numpy python-dev python-pip python-lxml }
  for script in packages do
    package script do
      action :install
    end
  end

when "rhel"

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
  package "python-pip" do 
    action :install
  end
  package "python-devel" do 
    action :install
  end
  package "python-lxml" do 
    action :install
  end
  package "python27-numpy" do
    action :install
  end

bash "pip-upgrade" do
    user "root"
    code <<-EOF
    set -e
    pip install --upgrade pip
EOF
end
    
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

# bazel_installation('bazel') do
#   version '0.3.1'
#   action :create
# end

#
#
# HDFS support in tensorflow
# https://github.com/tensorflow/tensorflow/issues/2218
#
magic_shell_environment 'HADOOP_HDFS_HOME' do
  value "#{node.apache_hadoop.base_dir}"
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




if node.cuda.enabled == "true"

# Check to see if i can find a cuda card. If not, fail with an error



bash "test_nvidia" do
    user "root"
    code <<-EOF
    set -e
    lspci | grep -i nvidia
EOF
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

# tensorflow_compile "tensorflow" do
#   action :tf
# end

# source $HADOOP_HOME/libexec/hadoop-config.sh
 # CLASSPATH=$($HADOOP_HDFS_HOME/bin/hdfs classpath --glob) python your_script.py


