#
# First, find out the compute capability of your GPU here: https://developer.nvidia.com/cuda-gpus
# E.g., 
# NVIDIA TITAN X	6.1
# GeForce GTX 1080	6.1
# GeForce GTX 970	5.2
#

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

# http://www.pyimagesearch.com/2016/07/04/how-to-install-cuda-toolkit-and-cudnn-for-deep-learning/
case node.platform_family
when "debian"

execute 'apt-get update -y'

#     freeglut3-dev g++-4.9 gcc-4.9 libglu1-mesa-dev libx11-dev libxi-dev libxmu-dev nvidia-modprobe python-dev python-pip python-virtualenv
  packages = %w{pkg-config zip g++ zlib1g-dev unzip swig git build-essential cmake unzip libopenblas-dev liblapack-dev linux-image-generic linux-image-extra-virtual linux-source linux-headers-generic }
  for script in packages do
    package script do
      action :install
    end
  end

when "rhel"

end


# On ec2 you need to disable the nouveau driver and reboot the machine
# http://www.pyimagesearch.com/2016/07/04/how-to-install-cuda-toolkit-and-cudnn-for-deep-learning/
#
template "/etc/modprobe.d/blacklist-nouveau.conf" do
  source "blacklist-nouveau.conf.erb"
  owner "root"
  mode 0775
end

# echo options nouveau modeset=0 | sudo tee -a /etc/modprobe.d/nouveau-kms.conf
# sudo update-initramfs -u
# sudo reboot



node.default.java.jdk_version = 8
node.default.java.set_etc_environment = true
node.default.java.oracle.accept_oracle_download_terms = true
include_recipe "java::oracle"


bazel_installation('bazel') do
  version '0.3.1'
  action :create
end

magic_shell_environment 'PATH' do
  value "$PATH:/usr/local/bin"
end


bash "install_numpy" do
    user "root"
    code <<-EOF
    pip install numpy 
EOF
end

if node.cuda.enabled == "true"

  base_cuda_file =  File.basename(node.cuda.url)
  base_cuda_dir =  File.basename(base_cuda_file, "_linux.run")
  cuda_dir = "/tmp/#{base_cuda_dir}"
  cached_file = "#{Chef::Config[:file_cache_path]}/#{base_cuda_file}"

  #remote_file cached_file do
  #  source node.cuda.url, node.cuda.url_backup
  #  mode 0755
  #  action :create
  #  not_if { File.exist?(cached_file) }
  #end

  bash "unpack_install_cuda" do
    user "root"
    timeout 14400
    code <<-EOF
    set -e
#    mkdir -p #{cuda_dir}
    cd #{Chef::Config[:file_cache_path]}

#    apt-get install software-properties-common -y
#    add-apt-repository ppa:graphics-drivers/ppa -y
#    apt-get install libcudart7.5 libnvrtc7.5 -y

     # installs into the /usr folder
#     apt-get install nvidia-cuda-toolkit nvidia-cuda-dev -y


     wget --quiet http://snurran.sics.se/hops/cuda_8.0.27_linux.run
     wget --quiet http://snurran.sics.se/hops/cuda_8.0.27.1_linux.run
     chmod +x cuda*
     ./cuda_8.0.27_linux.run --override --silent --driver --toolkit --no-opengl-libs
     ./cuda_8.0.27.1_linux.run --silent 
#    chmod +x #{base_cuda_file}
#    apt-get purge gcc -y
#    apt-get install gcc-4.9 -y
#    ./#{base_cuda_file} --silent --driver --toolkit --override

#    ./#{base_cuda_file} --extract=#{cuda_dir}
#    cd #{cuda_dir}
#    ./NVIDIA-Linux-x86_64-352.39.run
#    modprobe nvidia
#    ./cuda-linux64-rel-#{node.cuda.version}-19867135.run
#    ./cuda-samples-linux-#{node.cuda.version}-19867135.run

#    chown -R #{node.tensorflow.user}:#{node.tensorflow.group} #{node.cuda.version_dir}
#    chown #{node.tensorflow.user}:#{node.tensorflow.group} #{node.cuda.base_dir}
#    touch #{node.cuda.version_dir}/.installed
EOF
#  not_if { ::File.exists?( "#{node.cuda.version_dir}/.installed" ) }
  not_if { ::File.exists?( "#{Chef::Config[:file_cache_path]}/cuda_8.0.27.1_linux.run" ) }
end



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
  base_cudnn_dir =  File.basename(base_cudnn_file, "-ga.tgz")
  cudnn_dir = "/tmp/#{base_cudnn_dir}"
  cached_cudnn_file = "#{Chef::Config[:file_cache_path]}/#{base_cudnn_file}"

  remote_file cached_cudnn_file do
    #  checksum node.cuda.md5sum
    source node.cudnn.url
    mode 0755
    action :create
    not_if { File.exist?(cached_cudnn_file) }
  end

  bash "unpack_install_cdnn" do
    user "root"
    timeout 14400
    code <<-EOF
    set -e

    cd #{Chef::Config[:file_cache_path]}
    tar zxf #{cached_cudnn_file}
    cp -rf cuda/lib64 /usr
    cp -rf cuda/include/* /usr/include
    chmod a+r /usr/include/cudnn.h /usr/lib64/libcudnn*
# #{node.cuda.base_dir}

#    apt-get install python-pip python-dev python-virtualenv -y

#    chown -R #{node.tensorflow.user}:#{node.tensorflow.group} #{node.cuda.base_dir}
#    touch #{node.cuda.version_dir}/.cudnn_installed
EOF
    #  not_if { ::File.exists?( "#{node.cuda.version_dir}/.cudnn_installed" ) }
    not_if { ::File.exists?( "/usr/include/cudnn.h" ) }
  end


  tensorflow_compile "cdnn" do
    action :cdnn
  end


end

package "expect" do
 action :install
end

tensorflow_compile "tensorflow" do
  action :tf
end
