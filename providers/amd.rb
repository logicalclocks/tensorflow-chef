# coding: utf-8


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
#    sudo reboot

    package "libnuma-dev"
    #
    # Now REBOOT the server
    #
    
    
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
