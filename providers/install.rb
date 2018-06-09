action :cuda do

  cuda =  ::File.basename(node['cuda']['url'])
  
  bash "stop_xserver" do
    user "root"
    ignore_failure true
    code <<-EOF
      service lightdm stop
    EOF
  end

# Read the current version of installed cuda, if any  
cudaVersion = " "
if ::File.exist?( '/usr/local/cuda/version.txt')
  IO.foreach('/usr/local/cuda/version.txt') do |f|
    if f.include? "CUDA Version"
      cudaVersion = f.sub!('CUDA Version ', '')
      break
    end
  end 
end  
newCudaVersion = "#{node['cuda']['major_version']}.#{node['cuda']['minor_version']}"

Chef::Log.info "Old cuda version is: " + cudaVersion
Chef::Log.info "New cuda version is: " + newCudaVersion


bash "uninstall_cuda" do
    user "root"
    timeout 72000
    code <<-EOF
       if [[ "#{cudaVersion}" =~ ^[0-9]*.[0-9]* ]] ; then
         /usr/local/cuda/bin/uninstall_cuda_${BASH_REMATCH}.pl
       fi
    EOF
    not_if { "#{cudaVersion}" != "#{newCudaVersion}" || "#{cudaVersion}" != "" }        
end


driver =  ::File.basename(node['cuda']['driver_url'])    
case node['platform_family']
when "debian"

  bash "install_cuda" do
    user "root"
    timeout 72000
    code <<-EOF
    set -e
    apt-get install dkms -y
    cd #{Chef::Config['file_cache_path']}
    ./#{driver} -a --install-libglvnd --force-libglx-indirect -q --dkms --compat32-libdir -s
    ./#{cuda} --silent --driver
    ./#{cuda} --silent --toolkit --verbose
    ldconfig
    rm -f /usr/local/cuda
    ln -s /usr/local/cuda-#{node['cuda']['major_version']}  /usr/local/cuda
    EOF
    not_if { "#{cudaVersion}" == "#{newCudaVersion}" }    
  end

  bash "test_cuda" do
    user "root"
    code <<-EOF
      set -e
      nvidia-smi 
    EOF
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
      yum install epel-release dkms -y
# libstdc++.i686 -y
    EOF
  end


  #
  # for centos 7.2, this link is broken: /lib/modules/3.10.0-693.21.1.el7.x86_64/build
  # rm -f /lib/modules/3.10.0-693.21.1.el7.x86_64/build
  # ln -s /usr/src/kernels/3.10.0-862.3.2.el7.x86_64 /lib/modules/3.10.0-693.21.1.el7.x86_64/build
  #
#   bash "install_cuda_driver" do
#     user "root"
#     timeout 72000
#     code <<-EOF
#     set -e
#     cd #{Chef::Config['file_cache_path']}
#     # ./#{driver} -a --install-libglvnd --force-libglx-indirect -q --dkms
#     #./#{cuda} --silent --driver --verbose
# #    ./#{driver} -a --no-install-libglvnd  -q --dkms --compat32-libdir -s
#     EOF
#     not_if { "#{cudaVersion}" == "#{newCudaVersion}" }        
#   end


  bash "install_kernel_src_tools" do
    user "root"
    timeout 72000
    code <<-EOF
      set -e
      yum install rpm-build redhat-rpm-config asciidoc hmaccalc perl-ExtUtils-Embed pesign xmlto bison bc -y 
      yum install audit-libs-devel binutils-devel elfutils-devel elfutils-libelf-devel -y
      yum install ncurses-devel newt-devel numactl-devel pciutils-devel python-devel zlib-devel0 -y
    EOF
    not_if { "#{cudaVersion}" == "#{newCudaVersion}" }        
  end
  

  # bash "install_kernel_sources" do
  #   user node['kagent']['user']
  #   timeout 72000
  #   code <<-EOF
  #    set -e
  #    cd 
  #    mkdir -p ~/rpmbuild/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}
  #    echo '%_topdir %(echo $HOME)/rpmbuild' > ~/.rpmmacros
  #    ks=$(rpm -qa | grep kernel | head -1 | sed -e 's/kernel-//' | sed -e 's/\.x86_64//')
  #    centos_version=$(cat /etc/centos-release | sed -e 's/.*release //' | sed -e 's/ .*//')
  #    rpm -i http://vault.centos.org/${centos_version}/updates/Source/SPackages/kernel-${ks}.src.rpm 2>&1 | grep -v exist
  #    cd ~/rpmbuild/SPECS
  #    rpmbuild -bp --target=$(uname -m) kernel.spec
  #   EOF
  #   not_if { cudaVersion == newCudaVersion }
  # end


  # ELRepo
  # rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
  # rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-2.el7.elrepo.noarch.rpm
  #
  
  bash "install_cuda_full" do
    user "root"
    timeout 72000
    code <<-EOF
    set -e
    # https://devtalk.nvidia.com/default/topic/1012901/unable-to-install-driver-375-66-on-centos-7/?offset=5
    # There seems to be a non-standard installation path for the kernel sources in Centos
    # The 'ks=...' tries to resolve the directory where they should be installed inside /lib/modules/...
    # ks=$(rpm -qa | grep kernel | head -1 | sed -e 's/kernel-//' | sed -e 's/\.x86_64//')
    # ksl=$(rpm -qa | grep kernel | head -1 | sed -e 's/kernel-//')
    # --kernel-source-path==/home/#{node['kagent']['user']}/rpmbuild/BUILD/kernel-${ks}/linux-${ksl}/
    #
    #
    #
    #
#    rm -f /lib/modules/3.10.0-514.el7.x86_64/build
#    cd /lib/modules/3.10.0-514.el7.x86_64/build
#    ln -s /usr/src/kernels/3.10.0-693.21.1.el7.x86_64/ build
#     --kernel-source-path=/lib/modules/3.10.0-514.el7.x86_64/build
    cd #{Chef::Config['file_cache_path']}
# I have problems installing the kernel module (if you dont have it, and upgrade the kernel, the driver will break)
    ./#{cuda} --silent --driver --toolkit --verbose  --no-opengl-libs --no-drm 
    ldconfig
    rm -f /usr/local/cuda
    ln -s /usr/local/cuda-#{node['cuda']['major_version']}  /usr/local/cuda
    EOF
    not_if { "#{cudaVersion}" == "#{newCudaVersion}" }
  end

  bash "test_cuda" do
    user "root"
    code <<-EOF
      set -e
      nvidia-smi 
    EOF
  end

#   bash "install_cuda_rpm" do
#     user "root"
#     timeout 72000
#     code <<-EOF
#      set -e
#       cd #{Chef::Config['file_cache_path']}
#       rm -f cuda-repo-rhel7-8-0-local-ga2-#{node['cuda']['major_version']}.#{node['cuda']['minor_version']}-1.x86_64.rpm
#       wget #{node['download_url']}/cuda-repo-rhel7-8-0-local-ga2-#{node['cuda']['major_version']}.#{node['cuda']['minor_version']}-1.x86_64.rpm
#       rpm -ivh --replacepkgs cuda-repo-rhel7-8-0-local-ga2-#{node['cuda']['major_version']}.#{node['cuda']['minor_version']}-1.x86_64.rpm
#       yum clean expire-cache
#       yum install cuda -y
#       if [ ! -f /usr/lib64/libcuda.so ] ; then
#           ln -s /usr/lib64/nvidia/libcuda.so /usr/lib64
#       fi
#       rm -f cuda-repo-rhel*
#     EOF
#     not_if { ::File.exists?( "/usr/lib64/libcuda.so" ) && ::File.exists?( "/usr/local/cuda/version.txt" ) }
#   end

#   bash "install_cuda_rpm_patch" do
#     user "root"
#     timeout 72000
#     code <<-EOF
#  #     set -e
#       cd #{Chef::Config['file_cache_path']}
#       rm -f cuda-repo-rhel7-8-0-local-cublas-performance-update-#{node['cuda']['major_version']}.#{node['cuda']['minor_version']}-1.x86_64.rpm
#       wget #{node['download_url']}/cuda-repo-rhel7-8-0-local-cublas-performance-update-#{node['cuda']['major_version']}.#{node['cuda']['minor_version']}-1.x86_64.rpm
#       rpm -ivh --replacepkgs cuda-repo-rhel7-8-0-local-cublas-performance-update-#{node['cuda']['major_version']}.#{node['cuda']['minor_version']}-1.x86_64.rpm
# #      yum clean expire-cache
# #      yum update cuda -y
# #      yum upgrade
#       rm -f cuda-repo-rhel*
#     EOF
#     #not_if { ::File.exists?( "/usr/lib64/libcuda.so" ) }
#   end

end

# Install all the cuda patches

for i in 1..node['cuda']['num_patches'] do
  patch_version  = node['cuda']['major_version'] + "." + node['cuda']['minor_version'] + ".#{i}" 
  patch =  "cuda_#{patch_version}_linux.run"
  bash "install_cuda_patch_#{i}" do
    user "root"
    timeout 72000
    code <<-EOF
    set -e
    cd #{Chef::Config['file_cache_path']}
    ./#{patch} --silent --accept-eula
    EOF
    not_if { "#{cudaVersion}" == "#{newCudaVersion}" }
  end
end


#  link "/usr/lib64/libcuda.so" do
#    owner node['tensorflow']['user']
#    group node['tensorflow']['group']
#    to "/usr/lib64/nvidia/libcuda.so"
#  end



end


action :cudnn do

  base_cudnn_file =  ::File.basename(node['cudnn']['url'])
  cached_cudnn_file = "#{Chef::Config['file_cache_path']}/#{base_cudnn_file}"


  bash "unpack_install_cdnn" do
    user "root"
    timeout 14400
    code <<-EOF
    set -e

    cd #{Chef::Config['file_cache_path']}
    # Remove any old cuda directory that may have been lying around
    rm -rf cuda
    tar zxf #{cached_cudnn_file}
    cp -rf cuda/lib64/* /usr/local/cuda/lib64/
    cp -rf cuda/include/* /usr/include
    chmod a+r /usr/include/cudnn.h /usr/local/cuda/lib64/libcudnn*
    ldconfig
    EOF
  end

end




action :cpu do
  if node['tensorflow']['install'] == "dist"
    bash "install_tf_cpu" do
      user "root"
      code <<-EOF
    set -e
    pip install --upgrade http://storage.googleapis.com/tensorflow/linux/cpu/tensorflow-#{node['tensorflow']['version']}-cp27-none-linux_x86_64.whl --user
    EOF
    end
  end
  if node['tensorflow']['install'] == "src"
    bash "install_tf_cpu_from_src" do
      user "root"
      code <<-EOF
    set -e
    pip install --upgrade http://storage.googleapis.com/tensorflow/linux/cpu/tensorflow-#{node['tensorflow']['version']}-cp27-none-linux_x86_64.whl --user
    EOF
    end


  end
end

action :gpu do

  if node['tensorflow']['install'] == "dist"

    bash "install_tf_gpu" do
      user "root"
      code <<-EOF
    set -e
    pip install --upgrade http://storage.googleapis.com/tensorflow/linux/gpu/tensorflow_gpu-#{node['tensorflow']['version']}-cp27-none-linux_x86_64.whl --user
    EOF
    end
  end
  if node['tensorflow']['install'] == "src"
    bash "install_tf_gpu_from_src" do
      user "root"
      code <<-EOF
    set -e
    pip install --upgrade http://storage.googleapis.com/tensorflow/linux/gpu/tensorflow_gpu-#{node['tensorflow']['version']}-cp27-none-linux_x86_64.whl --user
    EOF
    end
  end

  bash "refresh_libs" do
      user "root"
      code <<-EOF
      ldconfig
    EOF
  end

end


action :conda_private do

# http://conda-test.pydata.org/docs/custom-channels.html
      bash "install_tfonspark_local_conda_repo" do
      user "root"
      code <<-EOF
        set -e
        conda index #{node['tensorflow']['base_dir']}/hopsconda/linux64
        conda -c hopsconda install hopstfonspark
        conda -c hopsconda install hopsutil
      EOF
    end


end
