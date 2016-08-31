action :cuda do

bash "validate_cuda" do
    user "root"
    code <<-EOF
    set -e
# test the cuda nvidia compiler
    su #{node.tensorflow.user} -l -c "nvcc -V"
EOF
end


end

action :cdnn do

bash "validate_cudnn" do
    user "root"
    code <<-EOF
    set -e
    su #{node.tensorflow.user} -l -c "nvidia-smi | grep NVID"
EOF
end

end

action :tf do

bash "install_bazel_again" do
    user "root"
    code <<-EOF
    set -e
    /var/chef/cache/bazel-0.3.1-installer-linux-x86_64.sh
EOF
end


bash "git_clone_tensorflow_server" do
    user node.tensorflow.user
    code <<-EOF
    set -e
    cd /home/#{node.tensorflow.user}

    git clone --recurse-submodules https://github.com/tensorflow/tensorflow
EOF
  not_if { ::File.exists?( "/home/#{node.tensorflow.user}/tensorflow/configure" ) }
end

if node.cuda.enabled == "true" 
   config="configure-expect-with-gpu.sh"
else
   config="configure-expect-no-gpu.sh"
end

template "/home/#{node.tensorflow.user}/tensorflow/#{config}" do
  source "#{config}.erb"
  owner node.tensorflow.user
  mode 0770
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

    bash "build_install_tensorflow_server" do
#      user 
      user "root"
      code <<-EOF
    set -e
    cd /home/#{node.tensorflow.user}/tensorflow
    bazel build -c opt --config=cuda //tensorflow/core/distributed_runtime/rpc:grpc_tensorflow_server


# Create the pip package and install

    bazel build -c opt --config=cuda //tensorflow/tools/pip_package:build_pip_package
    bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg

#    bazel build -c opt --config=cuda //tensorflow/cc:tutorials_example_trainer
#    bazel-bin/tensorflow/cc/tutorials_example_trainer --use_gpu

# tensorflow-0.10.0rc0-py2-none-any.whl
#    pip install /tmp/tensorflow_pkg/tensorflow-#{node.tensorflow.version}-py2-none-linux_x86_64.whl
    pip install /tmp/tensorflow_pkg/tensorflow-#{node.tensorflow.version}-py2-none-any.whl
    touch .installed
    chown #{node.tensorflow.user} .installed
    chown -R #{node.tensorflow.user} *
EOF
      not_if { ::File.exists?( "/home/#{node.tensorflow.user}/tensorflow/.installed" ) }
    end


  else
    bash "build_install_tensorflow_server_no_cuda" do
      user "root"
      code <<-EOF
    set -e
    cd /home/#{node.tensorflow.user}/tensorflow
    bazel build -c opt //tensorflow/core/distributed_runtime/rpc:grpc_tensorflow_server


# Create the pip package and install

    bazel build -c opt //tensorflow/tools/pip_package:build_pip_package
    bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg

#    bazel build -c opt //tensorflow/cc:tutorials_example_trainer
#    bazel-bin/tensorflow/cc/tutorials_example_trainer

#    pip install /tmp/tensorflow_pkg/tensorflow-#{node.tensorflow.version}-py2-none-linux_x86_64.whl
    pip install /tmp/tensorflow_pkg/tensorflow-#{node.tensorflow.version}-py2-none-any.whl
    touch .installed
    chown  #{node.tensorflow.user} .installed
    chown -R #{node.tensorflow.user} *
EOF
      not_if { ::File.exists?( "/home/#{node.tensorflow.user}/tensorflow/.installed" ) }
    end

  end


    bash "upgrade_protobufs" do
      user "root"
      code <<-EOF
       set -e
       pip install --upgrade https://storage.googleapis.com/tensorflow/linux/cpu/protobuf-3.0.0b2.post2-cp27-none-linux_x86_64.whl
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
