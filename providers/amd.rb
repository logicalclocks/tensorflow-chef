# coding: utf-8


action :install_rocm do

  # https://mc.ai/train-neural-networks-using-amd-gpus-and-keras/
  # https://rocm.github.io/ROCmInstall.html

  case node['platform_family']
  when "debian"
    platform="xenial"
    if node[:platform_version].to_f > 16.04
      platform="bionic"
    end

    package "linux-headers-#{node['kernel']['release']}"

    package "libnuma-dev"

    #
    # Now REBOOT the server
    #
    cached_file="#{node['rocm']['home']}/rocm_#{node['rocm']['version']}.zip"
    remote_file cached_file do
      source "#{node['rocm']['dist']}"
      mode 0755
      action :create
      retries 1
      not_if { ::File.exist?(cached_file) }
    end

    bash "add_local_rocm_repo" do
      user "root"
      cwd node['rocm']['home']
      code <<-EOF
        set -e
        unzip -o "./rocm_#{node['rocm']['version']}.zip"
        cat "./rocm_#{node['rocm']['version']}/rocm.gpg.key" | sudo apt-key add -
        echo "deb [trusted=yes arch=amd64] file://#{node['rocm']['home']}/rocm_#{node['rocm']['version']}/ xenial main" | sudo tee /etc/apt/sources.list.d/rocm.list
        chown -R _apt:root "#{node['rocm']['home']}/rocm_#{node['rocm']['version']}"
        apt-get update
      EOF
    end

    package "rocm-dkms" do
      version node['rocm']['version']
    end

    package "rocm-libs" do
      version node['rocm']['version']
    end

    package "miopen-hip" do
      version node['miopen-hip']['version']
    end

    package "cxlactivitylogger" do
      version node['cxlactivitylogger']['version']
    end

  when "rhel"

   # TODO
    
  end

  magic_shell_environment 'PATH' do
    value "$PATH:/opt/rocm/bin:/opt/rocm/profiler/bin:/opt/rocm/opencl/bin/x86_64"
  end
  
end