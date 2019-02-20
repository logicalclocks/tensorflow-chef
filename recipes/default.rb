private_ip = my_private_ip()

if node['tensorflow']['mpi'].eql? "true"
  node.override['tensorflow']['need_mpi'] = 1
end

if node['tensorflow']['tensorrt'].eql? "true"
  node.override['tensorflow']['need_tensorrt'] = 1
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

if node['tensorflow']['need_tensorrt'] == 1 && node['cuda']['accept_nvidia_download_terms'] == "true"

  case node['platform_family']
  when "debian"

    cached_file="#{Chef::Config['file_cache_path']}/#{node['cuda']['tensorrt_version']}"
    remote_file cached_file do
      source "#{node['download_url']}/#{node['cuda']['tensorrt_version']}"
      mode 0755
      action :create
      retries 1
      not_if { File.exist?(cached_file) }
    end

    tensorrt_dir="#{node['tensorflow']['dir']}/TensorRT-#{node['cuda']['tensorrt']}"
    bash "install-tensorrt-ubuntu" do
      user "root"
      code <<-EOF
       set -e
       cd #{Chef::Config['file_cache_path']}
       tar zxf #{cached_file}
       mv TensorRT-#{node['cuda']['tensorrt']} #{node['tensorflow']['dir']}
    EOF
      not_if "test -d #{tensorrt_dir}"
    end

    magic_shell_environment 'LD_LIBRARY_PATH' do
      value "$LD_LIBRARY_PATH:#{tensorrt_dir}/lib"
    end
  end
end

bash 'extract_sparkmagic' do 
  user "root"
  cwd Chef::Config['file_cache_path']
  code <<-EOF
    rm -rf #{node['conda']['dir']}/sparkmagic
    tar zxf sparkmagic-#{node['jupyter']['sparkmagic']['version']}.tar.gz
    mv sparkmagic #{node['conda']['dir']}
  EOF
end

# make sure Kerberos dev are installed 
case node['platform_family']
when "debian"
  package "libkrb5-dev"
when "rhel"
  package ["krb5-devel", "krb5-workstation"]
end


if node['amd']['rocm'].eql? "true"
  case node['platform_family']
  when "debian"
    package "rocm-libs"
    package "miopen-hip"
    package "cxlactivitylogger"

  when "rhel"

  end

end  


python_versions = node['kagent']['python_conda_versions'].split(',').map(&:strip)
for python in python_versions
  Chef::Log.info "Environment creation for: python#{python}"
  proj = "python" + python.gsub(".", "")
  rt1 = python.gsub(".", "")
  if rt1 = "36"
    rt1 = "35"
  end
  # assume that is python 2.7
  rt2 = "27mu"
  if python == "3.6"
    rt2 = "35m"
  end
  customTf=0
  if node['tensorflow']['custom_url'].start_with?("http://", "https://", "file://")
    begin
      uri = URI.parse(node['tensorflow']['custom_url'])
      %w( http https ).include?(uri.scheme)
      customTf=1
    rescue URI::BadURIError
      Chef::Log.warn "BadURIError custom_url for tensorflow: #{node['tensorflow']['custom_url']}"
      customTf=0
    rescue URI::InvalidURIError
      Chef::Log.warn "InvalidURIError custom_url for tensorflow: #{node['tensorflow']['custom_url']}"
      customTf=0
    end
  end



  
  bash "conda_py#{python}_env" do
    user node['conda']['user']
    group node['conda']['group']
    umask "022"
    environment ({ 'HOME' => ::Dir.home(node['conda']['user']), 'USER' => node['conda']['user'] })
    code <<-EOF
    cd $HOME
    export CONDA_DIR=#{node['conda']['base_dir']}
    export PY=`echo #{python} | sed -e "s/\.//"`
    export PROJECT=#{proj}
    export MPI=#{node['tensorflow']['need_mpi']}
    export CUSTOM_TF=#{customTf}

    ${CONDA_DIR}/bin/conda info --envs | grep "^${PROJECT}"
    if [ $? -ne 0 ] ; then
      ${CONDA_DIR}/bin/conda create -n $PROJECT python=#{python} -y -q
      if [ $? -ne 0 ] ; then
         exit 2
      fi
    fi

    yes | ${CONDA_DIR}/envs/${PROJECT}/bin/pip install --upgrade pip

    yes | ${CONDA_DIR}/envs/${PROJECT}/bin/pip install --upgrade requests
    if [ $? -ne 0 ] ; then
       exit 3
    fi

    if [ "#{python}" == "2.7" ] ; then
        yes | ${CONDA_DIR}/envs/${PROJECT}/bin/pip install --upgrade tensorflow-serving-api
        if [ $? -ne 0 ] ; then
          exit 4
        fi

        # See HOPSWORKS-870 for an explanation about this line    
        yes | ${CONDA_DIR}/envs/${PROJECT}/bin/pip install ipykernel==#{node['python2']['ipykernel_version']} ipython==#{node['python2']['ipython_version']} jupyter_console==#{node['python2']['jupyter_console_version']}
        if [ $? -ne 0 ] ; then
          exit 13
        fi
    else
        yes | ${CONDA_DIR}/envs/${PROJECT}/bin/pip install --upgrade ipykernel
        if [ $? -ne 0 ] ; then
          exit 14
        fi
    fi

    yes | ${CONDA_DIR}/envs/${PROJECT}/bin/pip install --upgrade hopsfacets
    if [ $? -ne 0 ] ; then
       exit 5
    fi

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

    if [ -f /sys/module/amdkfd/version ]  ; then
      rocm-smi
      if [ $? -eq 0 ] ; then
            yes | ${CONDA_DIR}/envs/${PROJECT}/bin/pip3 install --upgrade tensorflow-rocm
      fi
    fi



   # Install a custom build of tensorflow with this line.
    if [ $CUSTOM_TF -eq 1 ] ; then
      yes | #{node['conda']['base_dir']}/envs/${PROJECT}/bin/pip install --upgrade #{node['tensorflow']['custom_url']}/tensorflow${GPU}-#{node['tensorflow']['version']}-cp${PY}-cp${PY}mu-manylinux1_x86_64.whl --force-reinstall
    else
      yes | ${CONDA_DIR}/envs/${PROJECT}/bin/pip install tensorflow${GPU}==#{node['tensorflow']['version']}  --upgrade --force-reinstall
    fi
    if [ $? -ne 0 ] ; then
       exit 8
    fi

    export HOPS_UTIL_PY_VERSION=#{node['kagent']['hops-util-py-version']}
    if [ $HOPS_UTIL_PY_VERSION == "master" ] ; then
        yes | ${CONDA_DIR}/envs/${PROJECT}/bin/pip install git+https://github.com/logicalclocks/hops-util-py.git
    else
        yes | ${CONDA_DIR}/envs/${PROJECT}/bin/pip install hops==$HOPS_UTIL_PY_VERSION
    fi
    if [ $? -ne 0 ] ; then
       exit 9
    fi

    yes | ${CONDA_DIR}/envs/${PROJECT}/bin/pip install --upgrade pyjks
    if [ $? -ne 0 ] ; then
       exit 10
    fi

    yes | ${CONDA_DIR}/envs/${PROJECT}/bin/pip install --upgrade confluent-kafka
    if [ $? -ne 0 ] ; then
       exit 11
    fi

    yes | ${CONDA_DIR}/envs/${PROJECT}/bin/pip install --upgrade #{node['mml']['url']}
    if [ $? -ne 0 ] ; then
       exit 12
    fi

    EOF
  end


  
  bash "pydoop_py#{python}_env" do
    user "root"
    umask "022"
    code <<-EOF
    set -e
    export CONDA_DIR=#{node['conda']['base_dir']}
    export PROJECT=#{proj}
    su #{node['conda']['user']} -c "export HADOOP_HOME=#{node['install']['dir']}/hadoop; yes | ${CONDA_DIR}/envs/${PROJECT}/bin/pip install pydoop==#{node['pydoop']['version']}"
    EOF
  end

  bash "jupyter_sparkmagic" do
    user node['conda']['user']
    group node['conda']['group']
    umask "022"
    retries 1
    cwd "#{node['conda']['dir']}/sparkmagic"
    environment ({ 'HOME' => ::Dir.home(node['conda']['user']), 
                  'USER' => node['conda']['user'],
                  'JAVA_HOME' => node['java']['java_home'],
                  'CONDA_DIR' => node['conda']['base_dir'],
                  'HADOOP_HOME' => node['hops']['base_dir'],
                  'PROJECT' => proj})
    code <<-EOF
      set -e
      # Install packages
      yes | ${CONDA_DIR}/envs/${PROJECT}/bin/pip install --no-cache-dir --upgrade jupyter 
      yes | ${CONDA_DIR}/envs/${PROJECT}/bin/pip install --no-cache-dir --upgrade hdfscontents urllib3 requests pandas

      # Install packages to allow users to manage their jupyter extensions
      yes | ${CONDA_DIR}/envs/${PROJECT}/bin/pip install --no-cache-dir --upgrade jupyter_contrib_nbextensions jupyter_nbextensions_configurator 

      yes | ${CONDA_DIR}/envs/${PROJECT}/bin/pip install --upgrade ./hdijupyterutils ./autovizwidget ./sparkmagic

      # Enable kernels
      cd ${CONDA_DIR}/envs/${PROJECT}/lib/python#{python}/site-packages

      ${CONDA_DIR}/envs/${PROJECT}/bin/jupyter-kernelspec install sparkmagic/kernels/sparkkernel --sys-prefix
      ${CONDA_DIR}/envs/${PROJECT}/bin/jupyter-kernelspec install sparkmagic/kernels/pysparkkernel --sys-prefix 
      ${CONDA_DIR}/envs/${PROJECT}/bin/jupyter-kernelspec install sparkmagic/kernels/pyspark3kernel --sys-prefix
      ${CONDA_DIR}/envs/${PROJECT}/bin/jupyter-kernelspec install sparkmagic/kernels/sparkrkernel --sys-prefix

      # Enable extensions
      ${CONDA_DIR}/envs/${PROJECT}/bin/jupyter nbextension enable --py --sys-prefix widgetsnbextension

      ${CONDA_DIR}/envs/${PROJECT}/bin/jupyter contrib nbextension install --sys-prefix
      ${CONDA_DIR}/envs/${PROJECT}/bin/jupyter serverextension enable jupyter_nbextensions_configurator --sys-prefix
    EOF
  end

  if node['tensorflow']['need_tensorrt'] == 1 && node['cuda']['accept_nvidia_download_terms'] == "true"

    case node['platform_family']
    when "debian"

      bash "tensorrt_py#{python}_env" do
        user "root"
        umask "022"
        code <<-EOF
        set -e
        if [ -f /usr/local/cuda/version.txt ]  ; then
          nvidia-smi -L | grep -i gpu
          if [ $? -eq 0 ] ; then


          export CONDA_DIR=#{node['conda']['base_dir']}
          export PROJECT=#{proj}
          su #{node['conda']['user']} -c "cd #{tensorrt_dir}/python ; export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:#{tensorrt_dir}/lib ; yes | ${CONDA_DIR}/envs/${PROJECT}/bin/pip install tensorrt-#{node['cuda']['tensorrt']}"-cp#{rt1}-cp#{rt2}-linux_x86_64.whl"

          su #{node['conda']['user']} -c "cd #{tensorrt_dir}/uff ; export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:#{tensorrt_dir}/lib ; yes | ${CONDA_DIR}/envs/${PROJECT}/bin/pip install uff-0.2.0-py2.py3-none-any.whl"

#         su #{node['conda']['user']} -c "cd #{tensorrt_dir}/graphsurgeon ; export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:#{tensorrt_dir}/lib ; yes | ${CONDA_DIR}/envs/${PROJECT}/bin/pip install graphsurgeon-0.2.0-py2.py3-none-any.whl"

          fi
        fi

        EOF
      end

    end
  end

  
end

#
# Need to synchronize conda environments for newly joined or rejoining nodes.
#
package "rsync"

#
# Allow hopsworks/user to ssh into servers with the anaconda user to make a copy of environments.
#
homedir = node['conda']['user'].eql?("root") ? "/root" : "/home/#{node['conda']['user']}"
kagent_keys "#{homedir}" do
  cb_user "#{node['conda']['user']}"
  cb_group "#{node['conda']['group']}"
  cb_name "hopsworks"
  cb_recipe "default"
  action :get_publickey
end


if node['amd']['rocm'].eql? "true"
  group "video" do
    action :modify
    members ["#{node['hops']['yarn']['user']}", "#{node['hops']['yarnapp']['user']}"]
    append true
  end
end
