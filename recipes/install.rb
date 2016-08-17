# -*- coding: utf-8 -*-

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

  execute 'apt-get update'

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
# template "/etc/modprobe.d/blacklist-nouveau.conf" do
#   source "blacklist-nouveau.conf.erb"
#   owner node.tensorflow.hdfs.user
#   group node.tensorflow.group
#    mode 0775
# end

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


base_cuda_file =  File.basename(node.cuda.url)
base_cuda_dir =  File.basename(base_cuda_file, "_linux.run")
cuda_dir = "/tmp/#{base_cuda_dir}"
cached_file = "#{Chef::Config[:file_cache_path]}/#{base_cuda_file}"

remote_file cached_file do
#  checksum node.cuda.md5sum
  source node.cuda.url, node.cuda.url_backup
  mode 0755
  action :create
  not_if { File.exist?(cached_file) }
end

bash "unpack_install_cuda" do
    user "root"
    timeout 14400
    code <<-EOF
    set -e
    mkdir -p #{cuda_dir}
    cd #{Chef::Config[:file_cache_path]}
    chmod +x #{base_cuda_file}
    ./#{base_cuda_file} --silent --driver --toolkit 
#    ./#{base_cuda_file} --extract=#{cuda_dir}
#    cd #{cuda_dir}
#    ./NVIDIA-Linux-x86_64-352.39.run
#    modprobe nvidia
#    ./cuda-linux64-rel-#{node.cuda.version}-19867135.run
#    ./cuda-samples-linux-#{node.cuda.version}-19867135.run


#    ln -s  #{node.cuda.version_dir} #{node.cuda.base_dir}
    chown -R #{node.tensorflow.user}:#{node.tensorflow.group} #{node.cuda.version_dir}
    chown #{node.tensorflow.user}:#{node.tensorflow.group} #{node.cuda.base_dir}
    touch #{node.cuda.version_dir}/.installed
EOF
  not_if { ::File.exists?( "#{node.cuda.version_dir}/.installed" ) }
end


bash "validate_cuda" do
    user "root"
    code <<-EOF
    set -e
    export PATH=$PATH:#{node.cuda.base_dir}
    export LD_LIBRARY_PATH=#{node.cuda.base_dir}/lib64:$LD_LIBRARY_PATH"
    export CUDA_HOME==#{node.cuda.base_dir}
# test the cuda nvidia compiler
    nvcc -V
EOF
end

bash "unpack_install_cudnn" do
    user "root"
    code <<-EOF
    set -e
    cd #{cuda_dir}  
    rm -f cudnn-#{node.cuda.version}-linux-x64-v#{node.cudnn.version}-ga.tgz
    wget #{node.cudnn.url}
    tar -zxf cudnn-#{node.cuda.version}-linux-x64-v#{node.cudnn.version}-ga.tgz
    cd cuda
    cp -rf lib64/* #{node.cuda.base_dir}/lib64/
    cp -rf include/* #{node.cuda.base_dir}/include/
    chmod a+r #{node.cuda.base_dir}/lib64/libcudnn*

    chown -R #{node.tensorflow.user}:#{node.tensorflow.group} #{node.cuda.version_dir}
    chown #{node.tensorflow.user}:#{node.tensorflow.group} #{node.cuda.base_dir}
    touch #{node.cuda.version_dir}/.cudnn_installed
EOF
  not_if { ::File.exists?( "#{node.cuda.version_dir}/.cudnn_installed" ) }
end


bash "validate_cudnn" do
    user "root"
    code <<-EOF
    set -e
    export PATH=$PATH:#{node.cuda.base_dir}
    export LD_LIBRARY_PATH=#{node.cuda.base_dir}/lib64:$LD_LIBRARY_PATH"
    export CUDA_HOME==#{node.cuda.base_dir}

    nvidia-smi
EOF
end



magic_shell_environment 'PATH' do
  value "$PATH:#{node.cuda.base_dir}"
end

magic_shell_environment 'LD_LIBRARY_PATH' do
  value "#{node.cuda.base_dir}/lib64:$LD_LIBRARY_PATH"
end

magic_shell_environment 'CUDA_HOME' do
  value node.cuda.base_dir
end


bash "unpack_install_tensorflow_server" do
    user node.tensorflow.user
    code <<-EOF
    set -e
    cd /home/#{node.tensorflow.user}
    git clone –recurse-submodules https://github.com/tensorflow/tensorflow
    cd tensorflow
    ./configure
    bazel build -c opt –config=cuda //tensorflow/core/distributed_runtime/rpc:grpc_tensorflow_server
    bazel build -c opt –config=cuda //tensorflow/tools/pip_package:build_pip_package
    bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg

    pip install /tmp/tensorflow_pkg/tensorflow-#{node.tensorflow.version}-py2-none-linux_x86_64.whl
    touch tensorflow/.installed
EOF
  not_if { ::File.exists?( "/home/#{node.tensorflow.user}/tensorflow/.installed" ) }
end
