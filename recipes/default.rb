private_ip = my_private_ip()

# Only the first tensorflow server needs to create the directories in HDFS
if private_ip.eql? node['tensorflow']['default']['private_ips'][0]

  url=node['tensorflow']['hopstfdemo_url']

  base_filename =  "demo-#{node['tensorflow']['examples_version']}.tar.gz"
  cached_filename = "#{Chef::Config['file_cache_path']}/#{base_filename}"

  remote_file cached_filename do
    source url
    mode 0755
    action :create
  end

  # Extract Jupyter notebooks
  bash 'extract_notebooks' do
    user "root"
    code <<-EOH
                set -e
                cd #{Chef::Config['file_cache_path']}
                rm -rf #{node['tensorflow']['hopstfdemo_dir']}-#{node['tensorflow']['examples_version']}/#{node['tensorflow']['hopstfdemo_dir']}
                mkdir -p #{node['tensorflow']['hopstfdemo_dir']}-#{node['tensorflow']['examples_version']}/#{node['tensorflow']['hopstfdemo_dir']}
                tar -zxf #{base_filename} -C #{Chef::Config['file_cache_path']}/#{node['tensorflow']['hopstfdemo_dir']}-#{node['tensorflow']['examples_version']}/#{node['tensorflow']['hopstfdemo_dir']}
                chown -RL #{node['hops']['hdfs']['user']}:#{node['hops']['group']} #{Chef::Config['file_cache_path']}/#{node['tensorflow']['hopstfdemo_dir']}-#{node['tensorflow']['examples_version']}
        EOH
  end

  hops_hdfs_directory "/user/#{node['hops']['hdfs']['user']}/#{node['tensorflow']['hopstfdemo_dir']}" do
    action :create_as_superuser
    owner node['hops']['hdfs']['user']
    group node['hops']['group']
    mode "1775"
  end

  hops_hdfs_directory "#{Chef::Config['file_cache_path']}/#{node['tensorflow']['hopstfdemo_dir']}-#{node['tensorflow']['examples_version']}/#{node['tensorflow']['hopstfdemo_dir']}" do
    action :replace_as_superuser
    owner node['hops']['hdfs']['user']
    group node['hops']['group']
    mode "1755"
    dest "/user/#{node['hops']['hdfs']['user']}/#{node['tensorflow']['hopstfdemo_dir']}"
  end

  # Feature store tour artifacts
   url=node['featurestore']['hops_featurestore_demo_url']

   base_filename =  "demo-featurestore-#{node['featurestore']['examples_version']}.tar.gz"
   cached_filename = "#{Chef::Config['file_cache_path']}/#{base_filename}"

   remote_file cached_filename do
     source url
     mode 0755
     action :create
   end

  # Extract Feature Store Jupyter notebooks
   bash 'extract_notebooks' do
     user "root"
     code <<-EOH
                set -e
                cd #{Chef::Config['file_cache_path']}
                rm -rf #{node['featurestore']['hops_featurestore_demo_dir']}-#{node['featurestore']['examples_version']}/#{node['featurestore']['hops_featurestore_demo_dir']}
                mkdir -p #{node['featurestore']['hops_featurestore_demo_dir']}-#{node['featurestore']['examples_version']}/#{node['featurestore']['hops_featurestore_demo_dir']}
                tar -zxf #{base_filename} -C #{Chef::Config['file_cache_path']}/#{node['featurestore']['hops_featurestore_demo_dir']}-#{node['featurestore']['examples_version']}/#{node['featurestore']['hops_featurestore_demo_dir']}
                chown -RL #{node['hops']['hdfs']['user']}:#{node['hops']['group']} #{Chef::Config['file_cache_path']}/#{node['featurestore']['hops_featurestore_demo_dir']}-#{node['featurestore']['examples_version']}
     EOH
   end

   hops_hdfs_directory "/user/#{node['hops']['hdfs']['user']}/#{node['featurestore']['hops_featurestore_demo_dir']}" do
     action :create_as_superuser
     owner node['hops']['hdfs']['user']
     group node['hops']['group']
     mode "1775"
   end

   hops_hdfs_directory "#{Chef::Config['file_cache_path']}/#{node['featurestore']['hops_featurestore_demo_dir']}-#{node['featurestore']['examples_version']}/#{node['featurestore']['hops_featurestore_demo_dir']}" do
     action :replace_as_superuser
     owner node['hops']['hdfs']['user']
     group node['hops']['group']
     mode "1755"
     dest "/user/#{node['hops']['hdfs']['user']}/#{node['featurestore']['hops_featurestore_demo_dir']}"
   end

end
