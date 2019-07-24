case node["platform_family"]
when "debian"

  libpng_pkg_name = "libpng-dev"
  if node['platform_version'].eql?("16.04")
    libpng_pkg_name = "libpng12-dev"
  end

  package ["build-essential","curl","libcurl3-dev","git","libfreetype6-dev", libpng_pkg_name,"libzmq3-dev","pkg-config","python-dev","python-numpy","python-pip","software-properties-common","swig","zip","zlib1g-dev"]

  bash 'prepare_tf_serving' do
    user "root"
    #ignore_failure true
    code <<-EOF
      echo "deb [arch=amd64] http://storage.googleapis.com/tensorflow-serving-apt testing tensorflow-model-server tensorflow-model-server-#{node['tensorflow']['serving']['version']}" | sudo tee /etc/apt/sources.list.d/tensorflow-serving.list
      curl https://storage.googleapis.com/tensorflow-serving-apt/tensorflow-serving.release.pub.gpg | sudo apt-key add -        
      add-apt-repository ppa:ubuntu-toolchain-r/test -y
      apt-get update
    EOF
  end

  package ["libstdc++6", "tensorflow-model-server"]

when "rhel"
  package ["curl", "libcurl", "git", "freetype-devel", "libpng12-devel", "python2-pkgconfig", "python-devel", "python2-pip", "swig", "zip", "zlib-devel", "giflib-devel", "zeromq3-devel"]
end