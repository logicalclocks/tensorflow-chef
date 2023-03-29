action :driver do
  driver = ::File.basename(node['nvidia']['driver_url'])

  # Installation of the new driver will automatically remove the previous version of the driver as long as there
  # are no appliction using the driver.
  # So here we make sure the kmanager is not running and we kill all the yarnapp applications.
  # Probably not the best strategy, but there is no other way around it.

  service "nodemanager" do
    action :stop
    only_if "[ ( -f /usr/lib/systemd/system/nodemanager.service || -f /lib/systemd/system/nodemanager.service ) && \"$(modinfo nvidia | grep \"^version:\" | awk '{split($0,a,\" \"); print a[2]}')\" != \"#{new_resource.driver_version}\" ]"
  end

  yarnapp_user = node['install']['user'].empty? ? "yarnapp" : node['install']['user']
  if node.attribute?('hops') && node['hops'].attribute?('yarnapp') && node['hops']['yarnapp'].attribute?('user')
    yarnapp_user = node['hops']['yarnapp']['user']
  end

  bash "kill_apps" do
    user "root"
    returns [0, 1]
    code <<-EOF
      pkill -9 -u #{yarnapp_user}
    EOF
    only_if "[ getent passwd #{yarnapp_user} &&  \"$(modinfo nvidia | grep \"^version:\" | awk '{split($0,a,\" \"); print a[2]}')\" == \"#{new_resource.driver_version}\" ]"
  end

  cached_file = "#{Chef::Config['file_cache_path']}/#{driver}"
  remote_file cached_file do
    source node['nvidia']['driver_url']
    mode 0755
    action :create
    retries 1
    only_if  "[ \"$(modinfo nvidia | grep \"^version:\" | awk '{split($0,a,\" \"); print a[2]}')\" != \"#{new_resource.driver_version}\" ]"
  end

  case node['platform_family']
  when "debian"

    package 'dkms' do
      retries 10
      retry_delay 30
    end

    bash "install_driver_ubuntu" do
      user "root"
      timeout 72000
      cwd Chef::Config['file_cache_path']
      code <<-EOF
        set -e
        ./#{driver} -a --install-libglvnd --force-libglx-indirect -q --dkms --compat32-libdir -s --ui=none --no-cc-version-check
      EOF
      only_if  "[ \"$(modinfo nvidia | grep \"^version:\" | awk '{split($0,a,\" \"); print a[2]}')\" != \"#{new_resource.driver_version}\" ]"
    end

  when "rhel"

    # Obs! Versioned header install doesn't work [Jim]
    if node['rhel']['epel'].downcase == "true"
      package 'epel-release' do
        retries 10
        retry_delay 30
      end
    end

    # from https://docs.nvidia.com/ai-enterprise/deployment-guide-bare-metal/0.1.0/first-system.html
    package ['kernel-headers', 'kernel-devel', 'dkms', 'tar', 'bzip2', 'make', 'automake', 'gcc', 'gcc-c++', 'pciutils', 'libglvnd-devel'] do
      retries 10
      retry_delay 30
    end


    bash "install_driver_centos" do
      user "root"
      timeout 72000
      cwd Chef::Config['file_cache_path']
      code <<-EOF
        set -e
        # The NVIDIA driver requires that the kernel headers and development packages for the running
        # version of the kernel be installed at the time of the driver installation, as well whenever
        # the driver is rebuilt. For example, if your system is running kernel version 4.4.0, the 4.4.0
        # kernel headers and development packages must also be installed.
        ./#{driver} -a --install-libglvnd --force-libglx-indirect -q --dkms --compat32-libdir -s --ui=none --no-cc-version-check
      EOF
      only_if  "[ \"$(modinfo nvidia | grep \"^version:\" | awk '{split($0,a,\" \"); print a[2]}')\" != \"#{new_resource.driver_version}\" ]"
    end
  end
end
