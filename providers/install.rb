action :driver do
  driver = ::File.basename(node['nvidia']['driver_url'])

  # Installation of the new driver will automatically remove the previous version of the driver as long as there
  # are no appliction using the driver.
  # So here we make sure the kmanager is not running and we kill all the yarnapp applications.
  # Probably not the best strategy, but there is no other way around it.

  service "nodemanager" do
    action :stop
    only_if "[[ ( -f /usr/lib/systemd/system/nodemanager.service || -f /lib/systemd/system/nodemanager.service ) && \"$(modinfo nvidia | grep \"^version:\" | awk '{split($0,a,\" \"); print a[2]}')\" != \"#{new_resource.driver_version}\" ]]"
  end

  yarnapp_user = node['install']['user'].empty? ? "yarnapp" : node['install']['user']
  if node.attribute?('hops') && node['hops'].attribute?('yarn') && node['hops']['yarn'].attribute?('linux_container_local_user')
    yarnapp_user = node['hops']['yarn']['linux_container_local_user']
  end

  bash "kill_apps" do
    user "root"
    returns [0, 1]
    code <<-EOF
      pkill -9 -u #{yarnapp_user}
    EOF
    only_if "[[ getent passwd #{yarnapp_user} &&  \"$(modinfo nvidia | grep \"^version:\" | awk '{split($0,a,\" \"); print a[2]}')\" == \"#{new_resource.driver_version}\" ]]"
  end

  cached_file = "#{Chef::Config['file_cache_path']}/#{driver}"
  remote_file cached_file do
    source node['nvidia']['driver_url']
    mode 0755
    action :create
    retries 1
    only_if  "[[ \"$(modinfo nvidia | grep \"^version:\" | awk '{split($0,a,\" \"); print a[2]}')\" != \"#{new_resource.driver_version}\" ]]"
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
      only_if  "[[ \"$(modinfo nvidia | grep \"^version:\" | awk '{split($0,a,\" \"); print a[2]}')\" != \"#{new_resource.driver_version}\" ]]"
    end

  when "rhel"

    # Obs! Versioned header install doesn't work [Jim]
    package ['kernel-devel', 'kernel-headers', 'libglvnd-glx', 'epel-release', 'dkms', 'rpm-build', 'redhat-rpm-config', 'asciidoc', 'hmaccalc', 'perl-ExtUtils-Embed', 'pesign', 'xmlto', 'bison', 'bc', 'audit-libs-devel', 'binutils-devel', 'elfutils-devel', 'elfutils-libelf-devel', 'ncurses-devel', 'newt-devel', 'numactl-devel', 'pciutils-devel', 'python-devel', 'zlib-devel']

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
      only_if  "[[ \"$(modinfo nvidia | grep \"^version:\" | awk '{split($0,a,\" \"); print a[2]}')\" != \"#{new_resource.driver_version}\" ]]"
    end
  end
end

action :cuda do
  # new_resouce.version contains something like: 9.2.148_396.37~2
  # cuda_version_full will be 9.2.148_396.37
  cuda_version_full = new_resource.cuda_version.split('~')[0]

  # cuda_version_short: 9.2
  cuda_version_short = cuda_version_full.split('.')[0,2].join('.')

  # cuda_num_patches: 2
  cuda_num_patches = new_resource.cuda_version.split('~')[1].to_i

  # cuda_version_patches: 9.2.148
  cuda_version_patches = new_resource.cuda_version.split('_')[0]

  # Check if the current version is not yet installed
  cuda_version_installed = ::File.exist?("/usr/local/cuda-#{cuda_version_short}/version.txt")

  cuda_url = node['cuda']['base_url'] + "/cuda_#{cuda_version_full}_linux.run"
  cuda_binary = "cuda_#{cuda_version_full}_linux.run"
  cached_file = "#{Chef::Config['file_cache_path']}/#{cuda_binary}"

  remote_file cached_file do
    source cuda_url
    mode 0755
    action :create
    retries 2
    not_if { cuda_version_installed }
  end

  case node['platform_family']
  when "debian"

    bash "install_cuda" do
      user "root"
      timeout 72000
      cwd Chef::Config['file_cache_path']
      umask "022"
      code <<-EOF
        set -e
        # Remove link from previous installations
        rm -f /usr/local/cuda
        ./#{cuda_binary} --silent --toolkit --verbose --toolkitpath /usr/local/cuda-#{cuda_version_short}
      EOF
      not_if { cuda_version_installed }
    end

  when "rhel"

    # TODO(Fabio): not sure if we need these two more flags on centos.
    bash "install_cuda" do
      user "root"
      timeout 72000
      cwd Chef::Config['file_cache_path']
      umask "022"
      code <<-EOF
        set -e
        rm -f /usr/local/cuda
        ./#{cuda_binary} --silent --toolkit --verbose  --no-opengl-libs --no-drm --toolkitpath /usr/local/cuda-#{cuda_version_short}
      EOF
      not_if { cuda_version_installed }
    end
  end

  # Install all the cuda patches
  for i in 1..cuda_num_patches do
    patch = "cuda_#{cuda_version_patches}.#{i}_linux.run"
    patch_url  = "#{node['cuda']['base_url']}/#{patch}"
    patch_file = "#{Chef::Config['file_cache_path']}/#{patch}"

    remote_file patch_file do
      source patch_url
      mode 0755
      action :create
      retries 2
    end

    bash "install_cuda_patch_#{i}" do
      user "root"
      timeout 72000
      cwd Chef::Config['file_cache_path']
      umask "022"
      code <<-EOF
        set -e
        ./#{patch} --silent --accept-eula
        touch /usr/local/cuda-#{cuda_version_short}/.patch#{i}
      EOF
      not_if { ::File.exists?("/usr/local/cuda-#{cuda_version_short}/.patch#{i}") }
    end
  end
end


action :cudnn do

  # Check if the current version is not yet installed
  cudnn_version_installed = ::File.symlink?("/usr/local/cudnn-#{new_resource.cudnn_version}/lib64/libcudnn.so")

  base_cudnn_file = "cudnn-#{new_resource.cuda_version}-linux-x64-v#{new_resource.cudnn_version}.tgz"
  cached_cudnn_file = "#{Chef::Config['file_cache_path']}/#{base_cudnn_file}"
  url_cudnn_file = "#{node['cudnn']['base_url']}/#{base_cudnn_file}"

  remote_file cached_cudnn_file do
    source url_cudnn_file
    mode 755
    action :create
    retries 2
    not_if { cudnn_version_installed }
  end

  bash "unpack_install_cdnn-#{base_cudnn_file}" do
    user "root"
    cwd Chef::Config['file_cache_path']
    timeout 14400
    umask "022"
    code <<-EOF
      set -e
      # Remove any old cuda directory that may have been lying around in the tmp directory
      rm -rf cuda
      tar zxf #{cached_cudnn_file}
      mv cuda /usr/local/cudnn-#{new_resource.cudnn_version}
      chmod -R a+r /usr/local/cudnn-#{new_resource.cudnn_version}
    EOF
    not_if { cudnn_version_installed }
  end
end

action :nccl do
  nccl_version_short = new_resource.nccl_version.split('.')[0,2].join('.')
  nccl_dir_name = "nccl#{nccl_version_short}"

  # Check if the nccl version is already installed
  nccl_version_installed = ::File.directory?("/usr/local/#{nccl_dir_name}")

  nccl_file_name = "nccl_#{new_resource.nccl_version}+cuda#{new_resource.cuda_version}_x86_64"
  nccl_file_name_ext = "#{nccl_file_name}.txz"
  cached_nccl_file = "#{Chef::Config['file_cache_path']}/#{nccl_file_name_ext}"
  url_nccl_file = "#{node['nccl']['base_url']}/#{nccl_file_name_ext}"

  remote_file cached_nccl_file do
    source url_nccl_file
    mode 755
    action :create
    retries 2
    not_if { nccl_version_installed }
  end

  bash "install-#{nccl_dir_name}" do
    user "root"
    cwd Chef::Config['file_cache_path']
    umask "022"
    code <<-EOF
       set -e
       tar xf #{nccl_file_name_ext}
       mv #{nccl_file_name} /usr/local/#{nccl_dir_name}
    EOF
    not_if { nccl_version_installed }
  end
end
