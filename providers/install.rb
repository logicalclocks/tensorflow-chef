action :cuda do

  cuda =  ::File.basename(node.cuda.url)

case node.platform_family
when "debian"


  bash "install_cuda" do
    user "root"
    timeout 72000
    code <<-EOF
    set -e

    cd #{Chef::Config[:file_cache_path]}
    ./#{cuda} --silent --toolkit --driver --samples --verbose
    EOF
    not_if { ::File.exists?( "/usr/local/cuda/version.txt" ) }
  end

  patch =  ::File.basename(node.cuda.url_patch)  
  bash "install_cuda_patch" do
    user "root"
    timeout 72000
    code <<-EOF
    set -e
    cd #{Chef::Config[:file_cache_path]}
    ./#{patch} --silent --accept-eula 
    EOF
    not_if { ::File.exists?( "/usr/local/cuda/version.txt" ) }
  end

  
when "rhel"
  
  bash "install_cuda_preliminaries" do
    user "root"
    code <<-EOF
     set -e
# versioned header install doesnt work
#      yum install -y kernel-devel-$(uname -r)
#      yum install -y kernel-headers-$(uname -r)
      yum install kernel-devel -y
      yum install kernel-headers -y
      yum install libglvnd-glx -y
    EOF
    not_if { ::File.exists?( "/usr/local/cuda/version.txt" ) }
  end

  bash "install_cuda_rpm" do
    user "root"
    timeout 72000
    code <<-EOF
     set -e
      cd #{Chef::Config[:file_cache_path]}
      wget #{node['download_url']}/cuda-repo-rhel7-8-0-local-ga2-8.0.61-1.x86_64.rpm
      rpm -ivh --replacepkgs cuda-repo-rhel7-8-0-local-ga2-8.0.61-1.x86_64.rpm
      yum clean expire-cache
      yum install cuda -y
      if [ ! -f /usr/lib64/libcuda.so ] ; then
          ln -s /usr/lib64/nvidia/libcuda.so /usr/lib64
      fi
      rm -f cuda-repo-rhel*
    EOF
    not_if { ::File.exists?( "/usr/lib64/libcuda.so" ) }
  end

  bash "install_cuda_rpm_patch" do
    user "root"
    timeout 72000
    code <<-EOF
     set -e
      cd #{Chef::Config[:file_cache_path]}
      wget #{node['download_url']}/cuda-repo-rhel7-8-0-local-cublas-performance-update-8.0.61-1.x86_64.rpm
      rpm -ivh --replacepkgs cuda-repo-rhel7-8-0-local-cublas-performance-update-8.0.61-1.x86_64.rpm
      #yum clean expire-cache
      #yum inst cuda -y
      rm -f cuda-repo-rhel*
    EOF
    #not_if { ::File.exists?( "/usr/lib64/libcuda.so" ) }
  end

  
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
    cp -rf cuda/lib64/* /usr/local/cuda/lib64/
    cp -rf cuda/include/* /usr/include
    chmod a+r /usr/include/cudnn.h /usr/local/cuda/lib64/libcudnn*
    EOF
    not_if { ::File.exists?( "/usr/include/cudnn.h" ) }
  end

end




action :cpu do
  if node.tensorflow.install == "dist"
    bash "install_tf_cpu" do
      user "root"
      code <<-EOF
    set -e
    pip install --upgrade https://storage.googleapis.com/tensorflow/linux/cpu/tensorflow-#{node.tensorflow.version}-cp27-none-linux_x86_64.whl --user
    EOF
    end
  end
  if node.tensorflow.install == "src"
    bash "install_tf_cpu_from_src" do
      user "root"
      code <<-EOF
    set -e
    pip install --upgrade https://storage.googleapis.com/tensorflow/linux/cpu/tensorflow-#{node.tensorflow.version}-cp27-none-linux_x86_64.whl --user
    EOF
    end


  end
end

action :gpu do

  if node.tensorflow.install == "dist"
    
    bash "install_tf_gpu" do
      user "root"
      code <<-EOF
    set -e
    pip install --upgrade https://storage.googleapis.com/tensorflow/linux/gpu/tensorflow_gpu-#{node.tensorflow.version}-cp27-none-linux_x86_64.whl --user
    EOF
    end
  end
  if node.tensorflow.install == "src"
    bash "install_tf_gpu_from_src" do
      user "root"
      code <<-EOF
    set -e
    pip install --upgrade https://storage.googleapis.com/tensorflow/linux/gpu/tensorflow_gpu-#{node.tensorflow.version}-cp27-none-linux_x86_64.whl --user
    EOF
    end

  end
end
