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

    package "linux-headers-generic"
    package "libnuma-dev"
    #
    # Now REBOOT the server
    #

    
    driver_filename = ::File.basename(node['amd']['driver_ubuntu_url'])
    cached_file = "#{Chef::Config['file_cache_path']}/#{driver_filename}"
    base =  ::File.basename(cached_file, ".tar.xz")
    remote_file cached_file do
      source node['amd']['driver_ubuntu_url']
      mode 0755
      action :create
      retries 1
      not_if { ::File.exist?(cached_file) }
    end

#     bash "install-radeon-vii-driver" do
#       user "root"
#       code <<-EOF
#        set -e
#        cd #{Chef::Config['file_cache_path']}
#        tar -Jxf #{cached_file}
#        cd #{base}
#        ./amdgpu--pro-install --px --headless -y
# # Now, reboot the system
#        EOF
#       not_if { "dpkg -l amdpu-prod" }
#     end

    
    bash "install_amd_stuff" do
      user "root"
      code <<-EOF
        DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends libelf1 build-essential 
      EOF
    end
    
    
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

    # https://community.amd.com/thread/229198
    bash "force_rock_driver_conflict_amd_pro" do
      user "root"
      code <<-EOF
        sudo dpkg -i --force-overwrite /var/cache/apt/archives/rock-dkms_2.1-96_all.deb 
        apt install rocm-dkms rocm-opencl-dev -y
      EOF
    end


    tensorflow_compile 'initramfs' do
      action :kernel_initramfs
    end
    #
    # Now REBOOT the server
    #
    
  when "rhel"

   # TODO
    
  end

  group "video" do
    action :create
    not_if "getent group video"
  end


  magic_shell_environment 'PATH' do
    value "$PATH:/opt/rocm/bin:/opt/rocm/profiler/bin:/opt/rocm/opencl/bin/x86_64"
  end
  
end


action :install_rocm do

  if node[:platform_version].to_f <= 16.04
    bash "install_rocm" do
      user "root"
      code <<-EOF
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends curl \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends  libelf1  build-essential 
    apt-get clean &&  rm -rf /var/lib/apt/lists/*
      EOF
#    not_if { "/opt/rocm/bin/rocm-smi" }
    end
  else
    bash "install_rocm" do
      user "root"
      code <<-EOF
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends curl 
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends  libelf1 build-essential  gnupg
    DEBIAN_FRONTEND=noninteractive apt-get install -y rocm-libs miopen-hip cxlactivitylogger
    apt-get clean &&  rm -rf /var/lib/apt/lists/*
      EOF
#    not_if { "/opt/rocm/bin/rocm-smi" }
    end

  end

  #
  # Test now with the command:
  #   rocm-smi
  #
  bash "test_rocm" do
    user "root"
    code <<-EOF
      set -e
      /opt/rocm/bin/rocm-smi
    EOF
  end
  
end

