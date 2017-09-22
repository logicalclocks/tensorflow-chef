# coding: utf-8
action :kernel_initramfs do

  case node.platform_family
  when "debian"
    bash "kernel_initramfs" do
      user "root"
      code <<-EOF
      set -e
      update-initramfs -u
      EOF
    end
  when "rhel"
      bash "kernel_initramfs" do
        user "root"
        code <<-EOF
        set -e
        sudo dracut --force
        EOF
      end
  end

end

action :cuda do

bash "validate_cuda" do
    user "root"
    code <<-EOF
    set -e
# test the cuda nvidia compiler
    su #{node.tensorflow.user} -l -c "nvcc -V"
EOF
    not_if { node["cuda"]["skip_test"] == "true" }
end


end

action :cudnn do

bash "validate_cudnn" do
    user "root"
    code <<-EOF
    set -e
    su #{node.tensorflow.user} -l -c "nvidia-smi | grep NVID"
EOF
  not_if { node["cuda"]["skip_test"] == "true" }
end

end

action :tf do


  # https://github.com/lakshayg/tensorflow-build
  

bash "git_clone_tensorflow_server" do
    user node.tensorflow.user
    code <<-EOF
    set -e
    cd /home/#{node.tensorflow.user}

    git clone --recurse-submodules --branch v#{node.tensorflow.base_version} #{node.tensorflow.git_url}
#    cd tensorflow
#    git checkout v#{node.tensorflow.base_version}
EOF
  not_if { ::File.exists?( "/home/#{node.tensorflow.user}/tensorflow/configure" ) }
end

clang_path=""
if node.cuda.enabled == "true" 
  config="configure-no-expect-with-gpu.sh"
  case node.platform_family
  when "debian"
   clang_path="/usr/bin/clang"
  when "rhel"
   clang_path="/bin/clang"
  end
else
  config="configure-no-expect.sh"
end



template "/home/#{node.tensorflow.user}/tensorflow/#{config}" do
  source "#{config}.erb"
  owner node.tensorflow.user
  mode 0770
 variables({ :clang_path => clang_path })  
end


#
# http://www.admin-magazine.com/Articles/Automating-with-Expect-Scripts
#
bash "configure_tensorflow_server" do
    user node.tensorflow.user
    code <<-EOF
    set -e
    export LC_CTYPE=en_US.UTF-8
    export LC_ALL=en_US.UTF-8

    cd /home/#{node.tensorflow.user}/tensorflow
    ./#{config}
    
    # Check if configure completed successfully
    if [ ! -f tools/bazel.rc ] ; then
      exit 1
    fi
EOF
  not_if { ::File.exists?( "/home/#{node.tensorflow.user}/tensorflow/tools/bazel.rc" ) }
end


if node.cuda.enabled == "true" 

  # Try and download+install a custom python wheel first. If that fails, build from source
  begin
    wheel = File.basename("#{node['tensorflow']['custom_url']}")
    remote_file "#{Chef::Config[:file_cache_path]}/#{wheel}" do
      source node['tensorflow']['custom_url']
      owner node['tensorflow']['user']
      group node['tensorflow']['group']
      mode "0755"
     action :create_if_missing
    end

    bash "pip_install_custom_tensorflow" do
     user "root"
     code <<-EOF
      set -e
      export LC_CTYPE=en_US.UTF-8
      export LC_ALL=en_US.UTF-8
      pip install --ignore-installed --upgrade #{Chef::Config[:file_cache_path]}/#{wheel}
     EOF
    end
    
  rescue 

  
  # https://github.com/bazelbuild/bazel/issues/739
    bash "workaround_bazel_build" do
     user "root"
      code <<-EOF
    set -e
     chown -R #{node.tensorflow.user} /home/#{node.tensorflow.user}/tensorflow
#     rm -rf /home/#{node.tensorflow.user}/.cache/bazel
     EOF
    end



  case node.platform_family
  when "debian"

  bash "build_install_tensorflow_server_debian" do
    #    user node.tensorflow.user
      user "root"
      timeout 30800
      code <<-EOF
    set -e
    export LC_CTYPE=en_US.UTF-8
    export LC_ALL=en_US.UTF-8
    cd /home/#{node.tensorflow.user}/tensorflow
    ./#{config}

# Compile instructions - https://stackoverflow.com/questions/41293077/how-to-compile-tensorflow-with-sse4-2-and-avx-instructions
    export PATH=$PATH:/usr/local/bin
#    bazel build -c opt --config=cuda //tensorflow/core/distributed_runtime/rpc:grpc_tensorflow_server

# This works for ubuntu but not for centos
# Build fails for centos: https://github.com/tensorflow/tensorflow/issues/10665
#    bazel build -c opt  --cxxopt="-D_GLIBCXX_USE_CXX11_ABI=0" --config=cuda --copt=-mavx --copt=-mavx2 --copt=-mfma --copt=-mfpmath=both --copt=-msse4.1 --copt=-msse4.2 //tensorflow/tools/pip_package:build_pip_package

# This works
    bazel build -c opt --cxxopt="-D_GLIBCXX_USE_CXX11_ABI=0"  --config=cuda //tensorflow/tools/pip_package:build_pip_package
    touch .installed
EOF
      not_if { ::File.exists?( "/home/#{node.tensorflow.user}/tensorflow/.installed" ) }
    end

    
  when "rhel"

  bash "build_install_tensorflow_server_rhel" do
    #    user node.tensorflow.user
      user "root"
      timeout 30800
      code <<-EOF
    set -e
    export LC_CTYPE=en_US.UTF-8
    export LC_ALL=en_US.UTF-8
    cd /home/#{node.tensorflow.user}/tensorflow
    ./#{config}

# Compile instructions - https://stackoverflow.com/questions/41293077/how-to-compile-tensorflow-with-sse4-2-and-avx-instructions
    export PATH=$PATH:/usr/local/bin
#    bazel build -c opt --config=cuda //tensorflow/core/distributed_runtime/rpc:grpc_tensorflow_server

# This works for ubuntu but not for centos
# Build fails for centos: https://github.com/tensorflow/tensorflow/issues/10665
#    bazel build -c opt  --cxxopt="-D_GLIBCXX_USE_CXX11_ABI=0" --config=cuda --copt=-mavx --copt=-mavx2 --copt=-mfma --copt=-mfpmath=both --copt=-msse4.1 --copt=-msse4.2 //tensorflow/tools/pip_package:build_pip_package

# This works
    bazel build -c opt --cxxopt="-D_GLIBCXX_USE_CXX11_ABI=0 -I/usr/lib/gcc/x86_64-redhat-linux/4.8.5/include/*.h" --config=cuda //tensorflow/tools/pip_package:build_pip_package

    touch .installed
EOF
      not_if { ::File.exists?( "/home/#{node.tensorflow.user}/tensorflow/.installed" ) }
    end

    
  end

    


  bash "pip_install_tensorflow" do
    #    user node.tensorflow.user
      user "root"
      timeout 30800
      code <<-EOF
    set -e
    export LC_CTYPE=en_US.UTF-8
    export LC_ALL=en_US.UTF-8
    export PATH=$PATH:/usr/local/bin
    cd /home/#{node.tensorflow.user}/tensorflow

    #install -Dm755 bazel-bin/tensorflow/libtensorflow.so /usr/lib/
    #install -Dm644 tensorflow/c/c_api.h /usr/include/tensorflow-cuda/c_api.h


    bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg

    pip install --ignore-installed --upgrade /tmp/tensorflow_pkg/tensorflow-#{node.tensorflow.base_version}-py2-none-any.whl
    touch .installed_pip
EOF
      not_if { ::File.exists?( "/home/#{node.tensorflow.user}/tensorflow/.installed_pip" ) }
    end

  end   # End rescue
  
else

  # https://github.com/bazelbuild/bazel/issues/739
    bash "workaround_bazel_build" do
     user "root"
      code <<-EOF
    set -e
     chown -R #{node.tensorflow.user} /home/#{node.tensorflow.user}/tensorflow
     rm -rf /home/#{node.tensorflow.user}/.cache/bazel
     EOF
    end


  bash "build_install_tensorflow_server_no_cuda" do
    #     user node.tensorflow.user
      user "root"
      timeout 10800
      code <<-EOF
    set -e

    export LC_CTYPE=en_US.UTF-8
    export LC_ALL=en_US.UTF-8

    cd /home/#{node.tensorflow.user}/tensorflow
    ./#{config}

# Create the pip package and install
    export LC_CTYPE=en_US.UTF-8
    export LC_ALL=en_US.UTF-8

# Needed for Centos
    export PATH=$PATH:/usr/local/bin
    bazel build -c opt --copt=-mavx --copt=-mavx2 --copt=-mfma --copt=-mfpmath=both --copt=-msse4.1 --copt=-msse4.2 //tensorflow/tools/pip_package:build_pip_package
    bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg
    pip install /tmp/tensorflow_pkg/tensorflow-#{node.tensorflow.base_version}-cp27-cp27mu-linux_x86_64.whl  
    #--user
    touch .installed
EOF
      not_if { ::File.exists?( "/home/#{node.tensorflow.user}/tensorflow/.installed" ) }
    end
  end


    bash "upgrade_protobufs" do
      user "root"
      code <<-EOF
       set -e
       pip install --upgrade https://storage.googleapis.com/tensorflow/linux/cpu/protobuf-3.0.0b2.post2-cp27-none-linux_x86_64.whl 
       #--user
      EOF
    end


    bash "validate_tensorflow" do
      user node.tensorflow.user
      code <<-EOF
       set -e
#       cd /home/#{node.tensorflow.user}/tensorflow
#       cd models/image/mnist
#       python convolutional.py
      EOF
    end

end
