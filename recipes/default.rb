private_ip = my_private_ip()


# Only the first tensorflow server needs to create the directories in HDFS
if private_ip.eql? node['tensorflow']['default']['private_ips'][0]

  url=node['tensorflow']['hopstf_url']

  base_filename =  File.basename(url)
  cached_filename = "#{Chef::Config['file_cache_path']}/#{base_filename}"

  remote_file cached_filename do
    source url
    mode 0755
    action :create
  end

  hops_hdfs_directory cached_filename do
    action :put_as_superuser
    owner node['hops']['hdfs']['user']
    group node['hops']['group']
    mode "1755"
    dest "/user/#{node['hops']['hdfs']['user']}/#{base_filename}"
  end

  url=node['tensorflow']['hopstfdemo_url']

  base_filename =  File.basename(url)
  cached_filename = "#{Chef::Config['file_cache_path']}/#{base_filename}"

  remote_file cached_filename do
    source url
    mode 0755
    action :create
  end

  # Extract mnist
  bash 'extract_mnist' do
    user "root"
    code <<-EOH
                set -e
                tar -zxf #{Chef::Config['file_cache_path']}/#{base_filename} -C #{Chef::Config['file_cache_path']}
                chown -RL #{node['hops']['hdfs']['user']}:#{node['hops']['group']} #{Chef::Config['file_cache_path']}/#{node['tensorflow']['base_dirname']}
        EOH
    not_if { ::File.exists?("#{Chef::Config['file_cache_path']}/#{node['tensorflow']['base_dirname']}") }
  end

  hops_hdfs_directory "/user/#{node['hops']['hdfs']['user']}/#{node['tensorflow']['hopstfdemo_dir']}" do
    action :create_as_superuser
    owner node['hops']['hdfs']['user']
    group node['hops']['group']
    mode "1775"
  end

  hops_hdfs_directory "#{Chef::Config['file_cache_path']}/#{node['tensorflow']['base_dirname']}/*" do
    action :put_as_superuser
    owner node['hops']['hdfs']['user']
    group node['hops']['group']
    isDir true
    mode "1755"
    dest "/user/#{node['hops']['hdfs']['user']}/#{node['tensorflow']['hopstfdemo_dir']}"
  end

end

