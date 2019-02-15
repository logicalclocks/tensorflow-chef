# coding: utf-8


action :install_driver do

  # https://mc.ai/train-neural-networks-using-amd-gpus-and-keras/
  # https://rocm.github.io/ROCmInstall.html

  # lsmod | grep kfd
  # returns '0' if the AMD driver is loaded   

  case node['platform_family']
  when "debian"
    platform="xenial"
    if node[:platform_version].to_f > 16.04
      platform="bionic"
    end

#     package "linux-headers-4.13.0-32-generic"
#     package "linux-image-4.13.0-32-generic"
#     package "linux-image-extra-4.13.0-32-generic"
#     package "linux-signed-image-4.13.0-32-generic"
    package "linux-headers"
    package "libnuma-dev"
    #    sudo reboot

    #
    # Now REBOOT the server
    #

    
    driver_filename = File.basename(node['amd']['driver_ubuntu_url'])
    cached_file = "#{Chef::Config['file_cache_path']}/#{driver_filename}"
    base =  File.basename(cached_file, ".tar.xz")
    remote_file cached_file do
      source node['amd']['driver_ubuntu_url']
      mode 0755
      action :create
      retries 1
      not_if { File.exist?(cached_file) }
    end

    bash "install-radeon-vii-driver" do
      user "root"
      code <<-EOF
       set -e
       cd #{Chef::Config['file_cache_path']}
       tar -Jxf #{cached_file}
       cd #{base}
#       ./amdgpu-install -y
        ./amdgpu--pro-install --px --headless -y
#
# Now, reboot the system
# 
       EOF
      not_if "lsmod | grep amdgpu"
    end

    
    bash "install_amd_stuff" do
      user "root"
      code <<-EOF
        DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends libelf1 rocm-dev build-essential 
      EOF
    end
    
    
  # if [ -e /sys/module/amdkfd/version ]; then
  #   KERNEL_VERSION=$(cat /sys/module/amdkfd/version)
  #   KERNEL_SRC_VERSION=$(cat /sys/module/amdkfd/srcversion)    
  #   if [ "$KERNEL_VERSION" == "2.0.0" ]; then
  #       add_repo http://repo.radeon.com/rocm/apt/debian/
  # end

    apt_repository 'rocm' do
      uri "http://repo.radeon.com/rocm/apt/debian/"
      key "http://repo.radeon.com/rocm/apt/debian/rocm.gpg.key"
      arch "amd64"
      distribution platform
      cache_rebuild true
      components ['main']
      trusted true
      action :add
    end

    apt_update

    package "rocm-dkms"

    tensorflow_compile 'initramfs' do
      action :kernel_initramfs
    end
    #
    # Now REBOOT the server
    #
    
  when "rhel"

  end

  group "video" do
    action :create
    not_if "getent group video"
  end

  group "video" do
    action :modify
    members ["#{node['hops']['yarn']['user']}", "#{node['hops']['yarnapp']['user']}"]
    append true
  end


  magic_shell_environment 'PATH' do
    value "$PATH:/opt/rocm/bin:/opt/rocm/profiler/bin:/opt/rocm/opencl/bin/x86_64"
  end

    #
    # Test now with the command:
    #   rocm-smi
    #
  
end


action :install_rocm do

  if node[:platform_version].to_f <= 16.04
    bash "install_rocm" do
      user "root"
      code <<-EOF
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends curl \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends  libelf1 rocm-dev  build-essential 
    apt-get clean &&  rm -rf /var/lib/apt/lists/*
      EOF
      #    not_if { ::File.directory?("/usr/local/include/openmpi") }
    end
  else
    bash "install_rocm" do
      user "root"
      code <<-EOF
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends curl \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends  libelf1 rocm-dev  build-essential  gnupg
    apt-get clean &&  rm -rf /var/lib/apt/lists/*
      EOF
      #    not_if { ::File.directory?("/usr/local/include/openmpi") }
    end

  end

end

