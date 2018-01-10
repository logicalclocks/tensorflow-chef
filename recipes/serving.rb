case node["platform_family"]
when "debian"
  libs=%w{build-essential curl libcurl3-dev git libfreetype6-dev libpng12-dev libzmq3-dev pkg-config python-dev python-numpy python-pip software-properties-common swig zip zlib1g-dev }
when "rhel"
  libs=%w{build-essential curl libcurl git freetype-devel libpng12-devel python2-pkgconfig python-devel python27-python-pip swig zip zlib-devel giflib-devel zeromq3-devel }
end
for lib in libs
  package lib do
    action :install
  end
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


case node["platform_family"]
when "debian"

when "rhel"

end
