private_ip = my_private_ip()

if node['tensorflow']['mpi'].eql? "true"
  node.override['tensorflow']['need_mpi'] = 1
end

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


python_versions = %w{ 2.7 3.6 }
for python in python_versions

  bash "conda_py#{python}_env" do
    user node['conda']['user']
    group node['conda']['group']
    environment ({ 'HOME' => ::Dir.home(node['conda']['user']), 'USER' => node['conda']['user'] })
    code <<-EOF
    cd $HOME
    export CONDA_DIR=#{node['conda']['base_dir']}
    export PY=$(echo #{python} | sed 's/\.//')
    export PROJECT=python${python}
    export MPI=#{node['tensorflow']['need_mpi']}

    ${CONDA_DIR}/bin/conda info --envs | grep "^python${PY}"
    if [ $? -eq 0 ] ; then 
       exit 0
    fi

    ${CONDA_DIR}/bin/conda create -n $PROJECT python=#{python} -y -q


    export HADOOP_HOME=#{node['kagent']['dir']}/hadoop

    yes | ${CONDA_DIR}/envs/${PROJECT}/bin/pip install --pre --upgrade pydoop

    if [ "$PY" == "27" ] ; then
        yes | ${CONDA_DIR}/envs/${PROJECT}/bin/pip install --upgrade tensorflow-serving-api
    fi

    yes | ${CONDA_DIR}/envs/${PROJECT}/bin/pip install --upgrade hopsfacets
    yes | ${CONDA_DIR}/envs/${PROJECT}/bin/pip install --upgrade tfspark
    yes | ${CONDA_DIR}/envs/${PROJECT}/bin/pip install --upgrade ipykernel

    # Install a custom build of tensorflow with this line.
    ##{node['conda']['base_dir']}/envs/${PROJECT}/bin/pip install --upgrade #{node['conda']['base_dir']}/pkgs/tensorflow${GPU}-#{node['tensorflow']['version']}-cp${PY}-cp${PY}mu-manylinux1_x86_64.whl"


    # If cuda is installed, and there is a GPU, install TF with GPUs
    GPU=
    if [ -f /usr/local/cuda/version.txt ]  ; then
        nvidia-smi -L | grep -i gpu
    	if [ $? -eq 0 ] ; then
            GPU="-gpu"
            yes | ${CONDA_DIR}/envs/${PROJECT}/bin/pip uninstall tensorflow
    	    if [ $? -ne 0 ] ; then
                echo "Problem uninstalling tensorflow to prepare for gpu version"
            fi
        fi
    fi

    yes | ${CONDA_DIR}/envs/${PROJECT}/bin/pip install tensorflow${GPU}==#{node['tensorflow']['version']}  --upgrade --force-reinstall
    
    yes | ${CONDA_DIR}/envs/${PROJECT}/bin/pip install --upgrade hops

    if [ $MPI -eq 1 ] ; then
       yes | ${CONDA_DIR}/envs/${PROJECT}/bin/pip install --upgrade horovod
    fi

    yes | ${CONDA_DIR}/envs/${PROJECT}/bin/pip install --upgrade #{node['mml']['url']}

 EOF
  end

end
