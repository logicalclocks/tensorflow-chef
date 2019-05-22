# coding: utf-8


# https://mc.ai/train-neural-networks-using-amd-gpus-and-keras/
# https://rocm.github.io/ROCmInstall.html
action :install_rocm do

  case node['platform_family']
  when "debian"
    platform="xenial"
    if node[:platform_version].to_f > 16.04
      platform="bionic"
    end

    package "linux-headers-#{node['kernel']['release']}"

    package "libnuma-dev"

    cached_file="#{new_resource.rocm_home}/rocm_#{node['rocm']['debian']['version']}.tar.gz"
    remote_file cached_file do
      source "#{node['rocm']['dist']['debian']}"
      mode 0755
      action :create
      retries 1
      not_if { ::File.exist?(cached_file) }
    end

    # Local apt repo on the machine containing ROCm distribution
    bash "add_local_rocm_repo" do
      user "root"
      cwd new_resource.rocm_home
      code <<-EOF
        set -e
        tar -xvzf "./rocm_#{node['rocm']['debian']['version']}.tar.gz"
        cat "./rocm.gpg.key" | sudo apt-key add -
        echo "deb [trusted=yes arch=amd64] file://#{new_resource.rocm_home}/ xenial main" | sudo tee /etc/apt/sources.list.d/rocm.list
        chown -R _apt:root "#{new_resource.rocm_home}"
        apt-get update
      EOF
    end

    package "rocm-dkms" do
      version node['rocm']['debian']['version']
    end

    package "rocm-libs" do
      version node['rocm']['debian']['version']
    end

    package "miopen-hip" do
      version node['miopen-hip']['debian']['version']
    end

    package "cxlactivitylogger" do
      version node['cxlactivitylogger']['debian']['version']
    end

  when "rhel"

      package 'dkms'

      package "kernel-headers"

      package "kernel-devel"

      cached_file="#{new_resource.rocm_home}/rocm_#{node['rocm']['rhel']['version']}.tar.gz"
      remote_file cached_file do
        source "#{node['rocm']['dist']['rhel']}"
        mode 0755
        action :create
        retries 1
        not_if { ::File.exist?(cached_file) }
      end

      bash "extract repo" do
        user "root"
        cwd new_resource.rocm_home
        code <<-EOF
          set -e
          tar -xvzf "./rocm_#{node['rocm']['rhel']['version']}.tar.gz"
        EOF
      end

    # Local yum repo on the machine containing ROCm distribution
      yum_repository 'ROCm' do
        description 'ROCm yum repository'
        baseurl "file://#{new_resource.rocm_home}"
        gpgcheck false
        action :create
      end
      
      package "rocm-dkms" do
        version node['rocm']['rhel']['version']
      end

      package "rocm-libs" do
        version node['rocm']['rhel']['version']
      end

      package "miopen-hip" do
        version node['miopen-hip']['rhel']['version']
      end

      package "cxlactivitylogger" do
        version node['cxlactivitylogger']['rhel']['version']
      end
  end

  magic_shell_environment 'PATH' do
    value "$PATH:/opt/rocm/bin:/opt/rocm/profiler/bin:/opt/rocm/opencl/bin/x86_64"
  end
  
end