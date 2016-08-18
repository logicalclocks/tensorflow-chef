action :cuda do

bash "validate_cuda" do
    user node.tensorflow.user
    code <<-EOF
    set -e
#    export PATH=$PATH:#{node.cuda.base_dir}
#    export LD_LIBRARY_PATH=#{node.cuda.base_dir}/lib64:$LD_LIBRARY_PATH
#    export CUDA_HOME==#{node.cuda.base_dir}
# test the cuda nvidia compiler
    nvcc -V
EOF
end


end

action :cdnn do

bash "validate_cudnn" do
    user "root"
    code <<-EOF
    set -e
#    export PATH=$PATH:#{node.cuda.base_dir}
#    export LD_LIBRARY_PATH=#{node.cuda.base_dir}/lib64:$LD_LIBRARY_PATH
#    export CUDA_HOME==#{node.cuda.base_dir}

    nvidia-smi
EOF
end



end
