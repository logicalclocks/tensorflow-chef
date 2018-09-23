actions :cuda, :nccl, :cudnn

attribute :name, :kind_of => String, :name_attribute => true
attribute :cuda_versions, :kind_of => String
attribute :cudnn_versions, :kind_of => String
attribute :nccl_versions, :kind_of => String
