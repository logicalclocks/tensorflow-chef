private_ip = my_private_ip()


directory node.tensorflow.home do
  owner node.kagent.user
  group node.kagent.group
  mode "750"
  action :create
  recursive true
end

link node.tensorflow.base_dir do
  action :delete
  only_if "test -L #{node.tensorflow.base_dir}"
end

link node.tensorflow.base_dir do
  owner node.kagent.user
  group node.kagent.group
  to node.tensorflow.home
end

directory "#{node.tensorflow.home}/bin" do
  owner node.kagent.user
  group node.kagent.group
  mode "750"
  action :create
end

directory node.tensorflow.programs do
  owner node.kagent.user
  group node.kagent.group
  mode "750"
  action :create
end

directory node.tensorflow.logs do
  owner node.kagent.user
  group node.kagent.group
  mode "750"
  action :create
end

template "#{node.tensorflow.base_dir}/bin/launcher" do 
  source "launcher.sh.erb"
  owner node.kagent.user
  group node.kagent.group
  mode "750"
  # variables({
  #             :myNN => "hdfs://" + firstNN
  #           })
  action :create_if_missing
end

template "#{node.tensorflow.base_dir}/bin/kill-process.sh" do 
  source "kill-process.sh.erb"
  owner node.kagent.user
  group node.kagent.group
  mode "750"
  action :create_if_missing
end


