action :rocm do
  case node['platform_family']
  # Remove ROCm installation and all dependencies
  when "debian"
    bash "autoremove rocm and dependencies" do
      user "root"
      ignore_failure true
      cwd node['rocm']['home']
      code <<-EOF
        apt autoremove -y rocm-dkms rocm-dev rocm-utils
      EOF
    end
  when "rhel"
    bash "autoremove rocm and dependencies" do
      user "root"
      ignore_failure true
      cwd node['rocm']['home']
      code <<-EOF
        yum autoremove -y rocm-dkms rock-dkms
      EOF
    end
  end
end
