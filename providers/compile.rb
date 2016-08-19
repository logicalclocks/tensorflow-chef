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



bash "git_clone_tensorflow_server" do
    user node.tensorflow.user
    code <<-EOF
    set -e
    cd /home/#{node.tensorflow.user}
    git clone --recurse-submodules https://github.com/tensorflow/tensorflow
EOF
  not_if { ::File.exists?( "/home/#{node.tensorflow.user}/tensorflow/configure" ) }
end

bash "configure_tensorflow_server" do
    user node.tensorflow.user
    code <<-EOF
    set -e
    export LC_CTYPE=en_US.UTF-8
    export LC_ALL=en_US.UTF-8

    cd /home/#{node.tensorflow.user}/tensorflow
    /usr/bin/expect -c 'spawn ./configure
    expect "Please specify the location of python. [Default is /usr/bin/python]: "
    send "\r"
    expect "Do you wish to build TensorFlow with Google Cloud Platform support? [y/N] "
    send "N\r"
    expect "Default is [/usr/local/lib/python2.7/dist-packages]\n"
    send "\r"
    expect "Do you wish to build TensorFlow with GPU support? [y/N] "
    send "y\r"
    expect "Please specify which gcc should be used by nvcc as the host compiler. [Default is /usr/bin/gcc]: "
    send "\r"
    expect "Please specify the Cuda SDK version you want to use, e.g. 7.0. [Leave empty to use system default]: "
    send "#{node.cuda.major_version}\r"
    expect "Please specify the location where CUDA #{node.cuda.major_version} toolkit is installed. Refer to README.md for more details. [Default is /usr/local/cuda]: "
    send "/usr\r"
    expect "Please specify the Cudnn version you want to use. [Leave empty to use system default]: "
    send "#{node.cudnn.major_version}\r"
    expect "Refer to README.md for more details. [Default is /usr/local/cuda]: "
    send "\r"
    expect "[Default is: "3.5,5.2"]: "
    send "6.1\r"
    expect eof'
    
    # Check if configure completed successfully
    if [ ! -f tools/bazel.rc ] ;
      exit 1
    fi
EOF
  not_if { ::File.exists?( "/home/#{node.tensorflow.user}/tensorflow/tools/bazel.rc" ) }
end

bash "build_install_tensorflow_server" do
    user node.tensorflow.user
    code <<-EOF
    set -e
    cd /home/#{node.tensorflow.user}/tensorflow
    bazel build -c opt --config=cuda //tensorflow/core/distributed_runtime/rpc:grpc_tensorflow_server
    bazel build -c opt --config=cuda //tensorflow/tools/pip_package:build_pip_package
    bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg

    pip install /tmp/tensorflow_pkg/tensorflow-#{node.tensorflow.version}-py2-none-linux_x86_64.whl
    touch tensorflow/.installed
EOF
  not_if { ::File.exists?( "/home/#{node.tensorflow.user}/tensorflow/.installed" ) }
end


end
