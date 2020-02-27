case node["platform_family"]
when "debian"

  libpng_pkg_name = "libpng-dev"
  if node['platform_version'].eql?("16.04")
    libpng_pkg_name = "libpng12-dev"
  end

  package ["build-essential","curl","libcurl3-dev","git","libfreetype6-dev", libpng_pkg_name,"libzmq3-dev","pkg-config","python-dev","python-numpy","python-pip","software-properties-common","swig","zip","zlib1g-dev","libstdc++6"]

  # Download serving server
  model_server_dpkg = "#{Chef::Config['file_cache_path']}/tensorflow-model-server_#{node['tensorflow']['serving']['version']}_all.deb"
  remote_file model_server_dpkg do
    user "root"
    group "root"
    source node['tensorflow']['serving']['url']
    mode 0755
    action :create
  end

  dpkg_package "tensorflow-model-server" do
    source model_server_dpkg
    action :install
  end

when "rhel"
  package ["curl", "libcurl", "git", "freetype-devel", "libpng12-devel", "python2-pkgconfig", "python-devel", "python2-pip", "swig", "zip", "zlib-devel", "giflib-devel", "zeromq3-devel"]
end