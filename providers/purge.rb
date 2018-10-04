action :cuda do
  # Get all the cuda versions supported
  cuda_versions = []

  new_resource.cuda_versions.split(',').each do |cuda_version_full|
    cuda_versions.push(cuda_version_full.split('.')[0,2].join('.'))
  end

  # Iterate over the directories in /usr/local/cuda*
  # if a cuda version is not in the supported list, get rid of the installation
  ::Dir.glob("/usr/local/cuda-*").each do |cuda_dir|
    if !cuda_versions.include?(cuda_dir.split("-")[1])
      # This cuda version is not required anymore, get rid of the directory
      directory cuda_dir do
        recursive true
        action :delete
      end
    end
  end
end

action :cudnn do
  # Get all the cudnn versions supported
  cudnn_versions = []

  new_resource.cudnn_versions.split(',').each do |cudnn_version_full|
    cudnn_versions.push(cudnn_version_full.split('+')[0])
  end

  # Iterate over the directories in /usr/local/cudnn-*
  # if a cudnn version is not in the supported list, get rid of the installation
  ::Dir.glob("/usr/local/cudnn-*").each do |cudnn_dir|
    if !cudnn_versions.include?(cudnn_dir.split("-")[1])
      # This cudnn version is not required anymore, get rid of the directory
      directory cudnn_dir do
        recursive true
        action :delete
      end
    end
  end
end



action :nccl do
  # Get all the cuda versions supported
  nccl_versions = []

  new_resource.nccl_versions.split(',').each do |nccl_version_full|
    nccl_version.push(nccl_version_full.split('+')[1].split('.')[0,2].join('.'))
  end

  # Iterate over the directories in /usr/local/nccl*
  # if a cuda version is not in the supported list, get rid of the installation
  ::Dir.glob("/usr/local/nccl*").each do |nccl_dir|
    if !cuda_versions.include?(nccl_dir.slice!("nccl"))
      # This cuda version is not required anymore, get rid of the directory
      directory nccl_dir do
        recursive true
        action :delete
      end
    end
  end
end
