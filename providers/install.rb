action :cuda do

  cuda =  ::File.basename(node.cuda.url)

  bash "unpack_install_cuda" do
    user "root"
    timeout 72000
    code <<-EOF
    set -e

    cd #{Chef::Config[:file_cache_path]}
    ./#{cuda} --silent --toolkit --driver --samples --verbose
EOF
    not_if { ::File.exists?( "/usr/local/cuda/version.txt" ) }
  end



end


action :cudnn do

  base_cudnn_file =  ::File.basename(node.cudnn.url)
  cached_cudnn_file = "#{Chef::Config[:file_cache_path]}/#{base_cudnn_file}"


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
EOF
    not_if { ::File.exists?( "/usr/include/cudnn.h" ) }
  end



end




action :cpu do


bash "install_tf" do
    user "root"
    code <<-EOF
    set -e
    pip install --upgrade https://storage.googleapis.com/tensorflow/linux/cpu/tensorflow-#{node.tensorflow.version}-cp27-none-linux_x86_64.whl

EOF
end



end

action :gpu do

bash "install_tf" do
    user "root"
    code <<-EOF
    set -e
    pip install --upgrade https://storage.googleapis.com/tensorflow/linux/gpu/tensorflow-#{node.tensorflow.version}-cp27-none-linux_x86_64.whl

EOF
end


end
