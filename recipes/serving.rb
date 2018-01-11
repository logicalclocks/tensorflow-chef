
case node["platform_family"]
when "debian"
  libs=%w{build-essential curl libcurl3-dev git libfreetype6-dev libpng12-dev libzmq3-dev pkg-config python-dev python-numpy python-pip software-properties-common swig zip zlib1g-dev }
when "rhel"
  libs=%w{curl libcurl git freetype-devel libpng12-devel python2-pkgconfig python-devel python27-python-pip swig zip zlib-devel giflib-devel zeromq3-devel }
end

for lib in libs
  package lib do
    action :install
  end
end 


case node["platform_family"]
when "debian"

  bash 'install_tf_serving' do
    user "root"
    code <<-EOF
      set -e
      echo "deb [arch=amd64] http://storage.googleapis.com/tensorflow-serving-apt stable tensorflow-model-server tensorflow-model-server-universal" | sudo tee /etc/apt/sources.list.d/tensorflow-serving.list
      curl https://storage.googleapis.com/tensorflow-serving-apt/tensorflow-serving.release.pub.gpg | sudo apt-key add -        
      apt-get update
      apt-get install tensorflow-model-server
    EOF
    not_if "which tensorflow_model_server"
  end

  if node['install']['upgrade'] == "true" 
    bash 'upgrade_tf_serving' do
      user "root"
      code <<-EOF
      apt-get update
      apt-get update tensorflow-model-server
    EOF
    end
  end  
  
when "rhel"
  
  bzl =  File.basename(node['bazel']['url'])
  # https://gist.github.com/jarutis/6c2934705298720ff92a1c10f6a009d4
  bash "bazel-install-centos" do
    user "root"
    code <<-EOF
      set -e
      yum install patch -y
      yum -y install gcc gcc-c++ kernel-devel make automake autoconf swig git unzip libtool binutils
      yum -y install epel-release
      yum -y install python-devel python-pip
      yum -y install freetype-devel libpng12-devel zip zlib-devel giflib-devel zeromq3-devel
      pip install --target /usr/lib/python2.7/site-packages numpy
      pip install grpcio_tools mock
    EOF
  end
  bash "bazel-install" do
    user "root"
    code <<-EOF
      set -e
       cd #{Chef::Config['file_cache_path']}
       rm -f #{bzl}
       wget #{node['bazel']['url']}
       chmod +x bazel-*
       ./#{bzl} --user
       rm -rf /usr/bin/bazel
       ln -s /root/bin/bazel /usr/bin/bazel
       /usr/bin/bazel
    EOF
    not_if { File::exists?("/usr/bin/bazel") }
  end

  bash 'compile_tfserving_bazel' do
    user "root"
    code <<-EOF
      set -e
      pip install tensorflow-serving-api
      cd #{node['tensorflow']['dir']}/serving
      bazel build -c opt --copt=-mavx2 --define with_hdfs_support=true tensorflow_serving/model_servers:tensorflow_model_server
#      To build the entire tree, uncomment the line below
#      bazel build -c opt --define with_hdfs_support=true tensorflow_serving/...
#       bazel test -c opt tensorflow_serving/...
      rm -rf /usr/bin/tensorflow_model_server
      ln -s $(pwd)/tensorflow_serving/model_servers/tensorflow_model_server /usr/bin/
    EOF
    action :nothing
  end

  git "#{node['tensorflow']['dir']}/serving" do
    repository "https://github.com/tensorflow/serving.git"
    revision node['tensorflow']['serving']['version']
    action :sync
    enable_submodules true
    notifies :run, 'bash[compile_tfserving_bazel]', :immediately
  end

end

