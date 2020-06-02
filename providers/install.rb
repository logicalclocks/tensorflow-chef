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

    package 'dkms'

    bash "install_driver_ubuntu" do
      user "root"
      timeout 72000
      cwd Chef::Config['file_cache_path']
      code <<-EOF
        set -e
        ./#{driver} -a --install-libglvnd --force-libglx-indirect -q --dkms --compat32-libdir -s --ui=none
      EOF
      only_if  "[ \"$(modinfo nvidia | grep \"^version:\" | awk '{split($0,a,\" \"); print a[2]}')\" != \"#{new_resource.driver_version}\" ]"
    end

  when "rhel"

    # Obs! Versioned header install doesn't work [Jim]
    if node['rhel']['epel'].downcase == "true"
      package 'epel-release'
    end

    package ['kernel-headers', 'libglvnd-glx', 'dkms', 'rpm-build', 'redhat-rpm-config', 'asciidoc', 'hmaccalc', 'perl-ExtUtils-Embed', 'pesign', 'xmlto', 'bison', 'bc', 'audit-libs-devel', 'binutils-devel', 'elfutils-devel', 'elfutils-libelf-devel', 'ncurses-devel', 'newt-devel', 'numactl-devel', 'pciutils-devel', 'python-devel', 'zlib-devel']

    bash "install_driver_centos" do
      user "root"
      timeout 72000
      cwd Chef::Config['file_cache_path']
      code <<-EOF
        set -e
        # https://devtalk.nvidia.com/default/topic/1012901/unable-to-install-driver-375-66-on-centos-7/?offset=5
        # There seems to be a non-standard installation path for the kernel sources in Centos
        # The 'ks=...' tries to resolve the directory where they should be installed inside /lib/modules/...
        # ks=$(rpm -qa | grep kernel | head -1 | sed -e 's/kernel-//' | sed -e 's/\.x86_64//')
        # ksl=$(rpm -qa | grep kernel | head -1 | sed -e 's/kernel-//')
        # --kernel-source-path==/home/#{node['kagent']['user']}/rpmbuild/BUILD/kernel-${ks}/linux-${ksl}/
        #
        # rm -f /lib/modules/3.10.0-514.el7.x86_64/build
        # cd /lib/modules/3.10.0-514.el7.x86_64/build
        # ln -s /usr/src/kernels/3.10.0-693.21.1.el7.x86_64/ build
        #  --kernel-source-path=/lib/modules/3.10.0-514.el7.x86_64/build
        #
        ./#{driver} -a --install-libglvnd --force-libglx-indirect -q --dkms --compat32-libdir -s --ui=none
      EOF
      only_if  "[ \"$(modinfo nvidia | grep \"^version:\" | awk '{split($0,a,\" \"); print a[2]}')\" != \"#{new_resource.driver_version}\" ]"
    end
  end
end
