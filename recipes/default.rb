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


hops_version = "2.8.2"
if node.attribute?('hops') == true
  if node['hops'].attribute?('version') == true
    hops_version = node['hops']['version']
  end
end


python_versions = %w{ 2.7 3.6 }
for python in python_versions
  Chef::Log.info "Environment creation for: python#{python}"
  proj = "python" + python.gsub(".", "")
  
  bash "conda_py#{python}_env" do
    user node['conda']['user']
    group node['conda']['group']
    environment ({ 'HOME' => ::Dir.home(node['conda']['user']), 'USER' => node['conda']['user'] })
    code <<-EOF
    cd $HOME
    export CONDA_DIR=#{node['conda']['base_dir']}
    export PY=`echo #{python} | sed -e "s/\.//"`
    export PROJECT=#{proj}
    export MPI=#{node['tensorflow']['need_mpi']}
    export HADOOP_HOME=#{node['install']['dir']}/hadoop
    export HADOOP_VERSION=#{hops_version}
    export HADOOP_CONF_DIR=${HADOOP_HOME}/etc/hadoop

    ${CONDA_DIR}/bin/conda info --envs | grep "^${PROJECT}"
    if [ $? -ne 0 ] ; then 
      ${CONDA_DIR}/bin/conda create -n $PROJECT python=#{python} -y -q
      if [ $? -ne 0 ] ; then 
         exit 2
      fi
    fi

    yes | ${CONDA_DIR}/envs/${PROJECT}/bin/pip install --upgrade pip

    if [ "$python" == "2.7" ] ; then
        yes | ${CONDA_DIR}/envs/${PROJECT}/bin/pip install --upgrade tensorflow-serving-api
        if [ $? -ne 0 ] ; then 
          exit 4
        fi
    fi

    yes | ${CONDA_DIR}/envs/${PROJECT}/bin/pip install --upgrade hopsfacets
    if [ $? -ne 0 ] ; then 
       exit 5
    fi
    yes | ${CONDA_DIR}/envs/${PROJECT}/bin/pip install --upgrade tfspark
    if [ $? -ne 0 ] ; then 
       exit 6
    fi
    yes | ${CONDA_DIR}/envs/${PROJECT}/bin/pip install --upgrade ipykernel
    if [ $? -ne 0 ] ; then 
       exit 7
    fi

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
    if [ $? -ne 0 ] ; then 
       exit 8
    fi
    
    yes | ${CONDA_DIR}/envs/${PROJECT}/bin/pip install --upgrade hops
    if [ $? -ne 0 ] ; then 
       exit 9
    fi

    if [ $MPI -eq 1 ] ; then
       yes | ${CONDA_DIR}/envs/${PROJECT}/bin/pip install --upgrade horovod
       if [ $? -ne 0 ] ; then 
         exit 10
       fi
    fi

    yes | ${CONDA_DIR}/envs/${PROJECT}/bin/pip install --upgrade #{node['mml']['url']}
    if [ $? -ne 0 ] ; then 
       exit 11
    fi

    # yes | ${CONDA_DIR}/envs/${PROJECT}/bin/pip install pydoop==2.0a2 
    # if [ $? -ne 0 ] ; then 
    #    exit 3
    # fi


    cd ${CONDA_DIR}/anaconda/bin
    if [ $? -ne 0 ] ; then 
       exit 12
    fi
    source ./activate ${PROJECT}
    if [ $? -ne 0 ] ; then 
       exit 13
    fi
    YES | pip install pydoop==2.0a2
    if [ $? -ne 0 ] ; then
       exit 3
    fi

 EOF
  end

end

