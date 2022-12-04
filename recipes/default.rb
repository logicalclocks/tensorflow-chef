private_ip = my_private_ip()

is_head_node = false
if exists_local("hopsworks", "default") and exists_local("cloud", "default")
  unmanaged = false
  if node.attribute? 'cloud' and node['cloud'].attribute? 'init' and node['cloud']['init'].attribute? 'config' and node['cloud']['init']['config'].attribute? 'unmanaged'
    unmanaged = node['cloud']['init']['config']['unmanaged'].casecmp? 'true'
  end
  is_head_node = !unmanaged
end

is_first_tf_default_tor_run = private_ip.eql? node['tensorflow']['default']['private_ips'][0]

demo_owner = node['hops']['hdfs']['user']
demo_group = node['hops']['group']
demo_mode = "1775"

hopstfdemo_base_dir = "#{node['tensorflow']['hopstfdemo_dir']}-#{node['tensorflow']['examples_version']}"
hopstsdemo_dir = "#{hopstfdemo_base_dir}/#{node['tensorflow']['hopstfdemo_dir']}"
cached_hopstfdemo_dir = "#{Chef::Config['file_cache_path']}/#{hopstsdemo_dir}"
hdfs_hopstf_demo_dir = "/user/#{node['hops']['hdfs']['user']}/#{node['tensorflow']['hopstfdemo_dir']}"

if is_head_node || is_first_tf_default_tor_run 
  base_filename =  "demo-#{node['tensorflow']['examples_version']}.tar.gz"
  cached_filename = "#{Chef::Config['file_cache_path']}/#{base_filename}"

  remote_file cached_filename do
    source node['tensorflow']['hopstfdemo_url']
    mode 0755
    action :create
  end

  # Extract Jupyter notebooks
  bash 'extract_notebooks' do
    user "root"
    code <<-EOH
                set -e
                cd #{Chef::Config['file_cache_path']}
                rm -rf #{hopstfdemo_base_dir}
                mkdir -p #{hopstsdemo_dir}
                tar -zxf #{base_filename} -C #{cached_hopstfdemo_dir}
                chown -RL #{demo_owner}:#{demo_group} #{Chef::Config['file_cache_path']}/#{hopstfdemo_base_dir}
        EOH
  end
end 

# Only the first tensorflow server needs to create the directories in HDFS
if is_first_tf_default_tor_run

  hops_hdfs_directory hdfs_hopstf_demo_dir do
    action :create_as_superuser
    owner demo_owner
    group demo_group
    mode demo_mode
  end

  hops_hdfs_directory cached_hopstfdemo_dir do
    action :replace_as_superuser
    owner demo_owner
    group demo_group
    mode demo_mode
    dest hdfs_hopstf_demo_dir
  end
end

# if cloud enabled, then save the tours dirs and related info to disk to be used later during the upgrade 
if is_head_node
  hops_tours "Cache demo notebooks locally" do
    action :update_local_cache
    paths [cached_hopstfdemo_dir]
    hdfs_paths [hdfs_hopstf_demo_dir]
    owner demo_owner
    group demo_group
    mode demo_mode
  end
end 
