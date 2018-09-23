actions :cuda, :cudnn, :driver, :nccl

attribute :name, :kind_of => String, :name_attribute => true
attribute :driver_version, :kind_of => String
attribute :cuda_version, :kind_of => String
attribute :cudnn_version, :kind_of => String
attribute :nccl_version, :kind_of => String
