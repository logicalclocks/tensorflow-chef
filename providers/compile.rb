action :cuda do

bash "validate_cuda" do
    user node.tensorflow.user
    code <<-EOF
    set -e
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
    nvidia-smi | grep NVID
EOF
end



end
