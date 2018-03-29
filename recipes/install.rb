# First, find out the compute capability of your GPU here: https://developer.nvidia.com/cuda-gpus
# E.g.,
# NVIDIA TITAN X	6.1
# GeForce GTX 1080	6.1
# GeForce GTX 970	5.2
#

if node['cuda']['accept_nvidia_download_terms'].eql? "true"
  node.override['tensorflow']['need_cuda'] = 1
end
#
# If either 'infinband' or 'mpi' are selected, we have to build tensorflow from source.
#
if node['tensorflow']['mpi'].eql? "true"
  node.override['tensorflow']['need_mpi'] = 1
end

if node['tensorflow']['mkl'].eql? "true"
  node.override['tensorflow']['need_mkl'] = 1

  case node['platform_family']
  when "debian"

    bash "install-intel-mkl-ubuntu" do
      user "root"
      code <<-EOF
       set -e
       cd #{Chef::Config['file_cache_path']}
       rm -f l_mkl_2018.0.128.tgz
       wget http://snurran.sics.se/hops/l_mkl_2018.0.128.tgz
       tar zxf l_mkl_2018.0.128.tgz
       cd l_mkl_2018.0.128
#       echo "install -eula=accept installdir=#{node['tensorflow']['dir']}/intel_mkl" > commands.txt
#       ./install -s -eula=accept commands.txt
    EOF
    end

  when "rhel"
    bash "install-intel-mkl-rhel" do
      user "root"
      code <<-EOF
       set -e
       yum-config-manager --add-repo https://yum.repos.intel.com/setup/intelproducts.repo
       rpm --import https://yum.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB
       yum install intel-mkl-64bit-2017.3-056 -y
    EOF
    end
  end

end

if node['tensorflow']['rdma'].eql? "true"
  node.override['tensorflow']['need_rdma'] = 1
  if node['platform_family'].eql? "debian"

# Install inifiband
# https://community.mellanox.com/docs/DOC-2683
  bash "install-infiniband-ubuntu" do
    user "root"
    code <<-EOF
    set -e
     apt-get install libmlx4-1 libmlx5-1 ibutils  rdmacm-utils libibverbs1 ibverbs-utils perftest infiniband-diags libibverbs-dev -y
     apt-get -y install libibcm1 libibverbs1 ibverbs-utils librdmacm1 rdmacm-utils libdapl2 ibsim-utils ibutils libcxgb3-1 libibmad5 libibumad3 libmlx4-1 libmthca1 libnes1 infiniband-diags mstflint opensm perftest srptools
     # RDMA stack modules
     sudo modprobe rdma_cm
     sudo modprobe ib_uverbs
     sudo modprobe rdma_ucm
     sudo modprobe ib_ucm
     sudo modprobe ib_umad
     sudo modprobe ib_ipoib
     # RDMA devices low-level drivers
     sudo modprobe mlx4_ib
     sudo modprobe mlx4_en
     sudo modprobe iw_cxgb3
     sudo modprobe iw_cxgb4
     sudo modprobe iw_nes
     sudo modprobe iw_c2
    EOF
  end
  else # "rhel"
    # http://www.rdmamojo.com/2014/10/11/working-rdma-redhatcentos-7/
    # https://community.mellanox.com/docs/DOC-2086


# Get started - check hardware exists
# [root@hadoop5 install]#  lspci |grep -i infin
# 03:00.0 InfiniBand: QLogic Corp. IBA7322 QDR InfiniBand HCA (rev 02)
# [root@hadoop5 install]# lspci -Qvvs 03:00.0
    # The last line will tell you what kernel module you need to load. In my case, it was:
    # 	Kernel modules: ib_qib

    # modprobe ib_qib
    # lsmod | grep ib_
    # Then check it is installed

# [root@hadoop5 install]# ibstat
# CA 'qib0'
# 	CA type: InfiniPath_QLE7340
# 	Number of ports: 1
# 	Firmware version:
# 	Hardware version: 2
# 	Node GUID: 0x001175000076dcbe
# 	System image GUID: 0x001175000076dcbe
# 	Port 1:
# 		State: Active
# 		Physical state: LinkUp
# 		Rate: 40
# 		Base lid: 6
# 		LMC: 0
# 		SM lid: 3
# 		Capability mask: 0x07610868
# 		Port GUID: 0x001175000076dcbe
# 		Link layer: InfiniBand

    # To measure bandwith, on the server run: 'ib_send_bw'
    # On the client, 'ib_send_bw hadoop5'
#      ib_read_bw
# ---------------------------------------------------------------------------------------
# Device not recognized to implement inline feature. Disabling it

# ************************************
# * Waiting for client to connect... *
# ************************************
# ---------------------------------------------------------------------------------------
#                     RDMA_Read BW Test
#  Dual-port       : OFF		Device         : qib0
#  Number of qps   : 1		Transport type : IB
#  Connection type : RC		Using SRQ      : OFF
#  CQ Moderation   : 100
#  Mtu             : 2048[B]
#  Link type       : IB
#  Outstand reads  : 16
#  rdma_cm QPs	 : OFF
#  Data ex. method : Ethernet
# ---------------------------------------------------------------------------------------
#  local address: LID 0x06 QPN 0x000b PSN 0x2045ef OUT 0x10 RKey 0x030400 VAddr 0x007f9d36566000
#  remote address: LID 0x03 QPN 0x0013 PSN 0x8c947f OUT 0x10 RKey 0x070800 VAddr 0x007ff8638c7000
# ---------------------------------------------------------------------------------------
#  #bytes     #iterations    BW peak[MB/sec]    BW average[MB/sec]   MsgRate[Mpps]
#  65536      1000             2563.33            2563.29		   0.041013
# ---------------------------------------------------------------------------------------


  bash "install-infiniband-rhel" do
    user "root"
    code <<-EOF
    set -e
    yum -y groupinstall "Infiniband Support"
    yum --setopt=group_package_types=optional groupinstall "Infiniband Support" -y
    yum -y install perftest infiniband-diags
    systemctl start rdma.service

#    lsmod | grep mlx
#    yum install -y libmlx5 libmlx4 libibverbs libibumad librdmacm librdmacm-utils libibverbs-utils perftest infiniband-diags libibverbs-devel
#    modprobe mlx4_ib
#    modprobe mlx5_ib
   EOF
    not_if "systemctl status rdma"
  end
  end
end


group node['tensorflow']['group'] do
  action :create
  not_if "getent group #{node['tensorflow']['group']}"
end

user node['tensorflow']['user'] do
  action :create
  gid node['tensorflow']['group']
  manage_home true
  home "/home/#{node['tensorflow']['user']}"
  shell "/bin/bash"
  not_if "getent passwd #{node['tensorflow']['user']}"
end

group node['tensorflow']['group'] do
  action :modify
  members ["#{node['tensorflow']['user']}"]
  append true
  not_if "getent passwd #{node['tensorflow']['user']}"
end

# http://www.pyimagesearch.com/2016/07/04/how-to-install-cuda-toolkit-and-cudnn-for-deep-learning/
case node['platform_family']
when "debian"

  execute 'apt-get update -y'

  packages = %w{pkg-config zip g++ zlib1g-dev unzip swig git build-essential cmake unzip libopenblas-dev liblapack-dev linux-image-generic linux-image-extra-virtual linux-source linux-headers-generic python python-numpy python-dev python-pip python-lxml python-pillow libcupti-dev libcurl3-dev python-wheel python-six }
  for lib in packages do
    package lib do
      action :install
    end
  end

when "rhel"

  bash "pip-prepare-yum-epel-release-add" do
    user "root"
    code <<-EOF
    set -e
    yum install epel-release -y
    yum install python-pip -y
    yum install mlocate -y
    updatedb

# For yum repo for Nvidia
#   yum-config-manager --add-repo=https://negativo17.org/repos/epel-nvidia.repo
EOF
  end

  packages = %w{gcc gcc-c++ kernel-devel openssl openssl-devel python python-devel python-lxml python-pillow libcurl-devel python-wheel python-six }
  for lib in packages do
    package lib do
      action :install
    end
  end

  # https://negativo17.org/nvidia-driver/
 # nvidia_packages = %w{ nvidia-driver nvidia-driver-libs.x86_64 dkms-nvidia cuda-devel cuda-libs cuda-cudnn cuda-cudnn-devel cuda-cli-tools cuda-cupti-devel cuda-extra-libs }
 #  for driver in nvidia_packages do
 #    package driver do
 #      action :install
 #    end
 #  end


end

bash "pip-upgrade" do
    user "root"
    code <<-EOF
    set -e
    pip install --upgrade pip
    EOF
end

# On ec2 you need to disable the nouveau driver and reboot the machine
# http://www.pyimagesearch.com/2016/07/04/how-to-install-cuda-toolkit-and-cudnn-for-deep-learning/
#
template "/etc/modprobe.d/blacklist-nouveau.conf" do
  source "blacklist-nouveau.conf.erb"
  owner "root"
  mode 0775
end

tensorflow_compile "initram" do
  action :kernel_initramfs
end

# echo options nouveau modeset=0 | sudo tee -a /etc/modprobe.d/nouveau-kms.conf
# sudo update-initramfs -u
# sudo reboot

node.default['java']['jdk_version'] = 8
node.default['java']['set_etc_environment'] = true
node.default['java']['oracle']['accept_oracle_download_terms'] = true
include_recipe "java::oracle"

if node['tensorflow']['install'].eql?("src")

  bzl =  File.basename(node['bazel']['url'])
  case node['platform_family']
  when "debian"

    bash "bazel-install-ubuntu" do
      user "root"
      code <<-EOF
      set -e
       apt-get install pkg-config zip g++ zlib1g-dev unzip -y
    EOF
    end

  when "rhel"

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
       /usr/local/bin/bazel
    EOF
    not_if { File::exists?("/usr/local/bin/bazel") }
  end

end

#
#
# HDFS support in tensorflow
# https://github.com/tensorflow/tensorflow/issues/2218
#
magic_shell_environment 'HADOOP_HDFS_HOME' do
  value "#{node['hops']['base_dir']}"
end

magic_shell_environment 'LD_LIBRARY_PATH' do
  value "$LD_LIBRARY_PATH:$JAVA_HOME/jre/lib/amd64/server::/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64"
end

magic_shell_environment 'PATH' do
  value "$PATH:/usr/local/bin"
end

magic_shell_environment 'CUDA_HOME' do
  value "/usr/local/cuda"
end


if node['cuda']['accept_nvidia_download_terms'].eql?("true")
  # Check to see if i can find a cuda card. If not, fail with an error
  package "clang"

  bash "test_nvidia" do
    user "root"
    code <<-EOF
    set -e
    lspci | grep -i nvidia
  EOF
    not_if { node['cuda']['skip_test'] == "true" }
  end

  cuda =  File.basename(node['cuda']['url'])
  base_cuda_dir =  File.basename(cuda, "_linux-run")
  cuda_dir = "/tmp/#{base_cuda_dir}"
  cached_file = "#{Chef::Config['file_cache_path']}/#{cuda}"


  remote_file cached_file do
    source node['cuda']['url']
    mode 0755
    action :create
    retries 2
    ignore_failure true
    not_if { File.exist?(cached_file) }
  end

  patch =  File.basename(node['cuda']['url_patch'])
  base_patch_dir =  File.basename(patch, "_linux-run")
  patch_dir = "/tmp/#{base_patch_dir}"
  patch_file = "#{Chef::Config['file_cache_path']}/#{patch}"

  remote_file patch_file do
    source node['cuda']['url_patch']
    mode 0755
    action :create
    retries 2
    ignore_failure true
    not_if { File.exist?(patch_file) }
  end


  driver =  File.basename(node['cuda']['driver_url'])
  cached_file = "#{Chef::Config['file_cache_path']}/#{driver}"


  remote_file cached_file do
    source node['cuda']['driver_url']
    mode 0755
    action :create
    retries 1
    not_if { File.exist?(cached_file) }
  end

  tensorflow_install "cuda_install" do
    action :cuda
  end


  #    cd #{cuda_dir}
  #    ./NVIDIA-Linux-x86_64-352.39.run
  #    modprobe nvidia
  #    ./cuda-linux64-rel-#{node['cuda']['version']}-19867135.run
  #    ./cuda-samples-linux-#{node['cuda']['version']}-19867135.run


  magic_shell_environment 'PATH' do
    value "$PATH:#{node['cuda']['base_dir']}/bin"
  end

  magic_shell_environment 'LD_LIBRARY_PATH' do
    value "#{node['cuda']['base_dir']}/lib64:$LD_LIBRARY_PATH"
  end

  magic_shell_environment 'CUDA_HOME' do
    value node['cuda']['base_dir']
  end


  tensorflow_compile "cuda" do
    action :cuda
  end

  base_cudnn_file =  File.basename(node['cudnn']['url'])
  cached_cudnn_file = "#{Chef::Config['file_cache_path']}/#{base_cudnn_file}"

  remote_file cached_cudnn_file do
    source node['cudnn']['url']
    mode 0755
    action :create
    retries 2
    not_if { File.exist?(cached_cudnn_file) }
  end


  tensorflow_install "cudnn_install" do
    action :cudnn
  end


  tensorflow_compile "cdnn" do
    action :cudnn
  end

  tensorflow_install "gpu_install" do
    action :gpu
  end

else
  tensorflow_install "cpu_install" do
    action :cpu
  end
end


if node['tensorflow']['mpi'] == "true"
  
  case node['platform_family']
  when "debian"
    package "openmpi-bin"
    package "libopenmpi-dev"
    package "mpi-default-bin"

#     bash "install-nccl2-ubuntu" do
#       user "root"
#       code <<-EOF
# #       set -e
#        cd #{Chef::Config['file_cache_path']}
#        rm -f nccl-repo-ubuntu1604-2.0.5-ga-cuda8.0_2-1_amd64.deb
#        wget http://snurran.sics.se/hops/nccl-repo-ubuntu1604-2.0.5-ga-cuda8.0_2-1_amd64.deb
#        dpkg -i nccl-repo-ubuntu1604-2.0.5-ga-cuda8.0_2-1_amd64.deb
#        apt-key add /var/nccl-repo-2.0.5-ga-cuda8.0/7fa2af80.pub
#        apt update
#        apt install libnccl2 libnccl-dev

#        # https://github.com/uber/horovod/blob/master/docs/gpus.md
#        # HOROVOD_GPU_ALLGATHER=MPI HOROVOD_GPU_BROADCAST=MPI HOROVOD_GPU_ALLREDUCE=NCCL pip install --no-cache-dir horovod
#        # HOROVOD_GPU_ALLREDUCE=MPI HOROVOD_GPU_ALLGATHER=MPI HOROVOD_GPU_BROADCAST=MPI pip install --no-cache-dir horovod
#     EOF
#     end

  when "rhel"
    # installs binaries to /usr/local/bin
    # horovod needs mpicxx in /usr/local/bin/mpicxx - add it to the PATH
    package "openmpi-devel"
    
    magic_shell_environment 'PATH' do
      value "$PATH:#{node['cuda']['base_dir']}/bin:/usr/local/bin"
    end    
  end

    magic_shell_environment 'LD_LIBRARY_PATH' do
      value "$LD_LIBRARY_PATH:$JAVA_HOME/jre/lib/amd64/server:/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64:/usr/local/nccl2/lib"
    end
  

    nccl2=node['cuda']['nccl_version']
    bash "install-nccl2" do
      user "root"
      code <<-EOF
       set -e
       cd #{Chef::Config['file_cache_path']}
       rm -f #{nccl2}.txz
       wget http://snurran.sics.se/hops/#{nccl2}.txz
       rm -f #{nccl2}.tar
       xz -d #{nccl2}.txz
       rm -rf #{nccl2}
       tar xf #{nccl2}.tar
       rm -rf /usr/local/#{nccl2}
       mv  #{nccl2} /usr/local
       rm -f /usr/local/nccl2
       ln -s /usr/local/#{nccl2} /usr/local/nccl2
    EOF
      not_if { File.directory?("/usr/local/#{nccl2}") }
    end
  
end

if node['tensorflow']['install'].eql?("src")

    # https://wiki.fysik.dtu.dk/niflheim/OmniPath#openmpi-configuration
    # compile openmpi on centos 7
    # https://bitsanddragons.wordpress.com/2017/05/08/install-openmpi-2-1-0-on-centos-7/

    tensorflow_compile "mpi-compile" do
      action :openmpi
    end

  tensorflow_compile "tensorflow" do
    action :tf
  end

end

template "/etc/ld.so.conf.d/gpu.conf" do
  source "gpu.conf.erb"
  owner "root"
  group "root"
  mode "644"
end

bash "ldconfig" do
  user "root"
  code <<-EOF
     ldconfig
  EOF
end
