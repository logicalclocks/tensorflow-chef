action :cpu do


bash "install_tf" do
    user "root"
    code <<-EOF
    pip install --upgrade https://storage.googleapis.com/tensorflow/linux/cpu/tensorflow-#{node.tensorflow.version}-cp27-none-linux_x86_64.whl

EOF
end



end

action :gpu do

bash "install_tf" do
    user "root"
    code <<-EOF
    pip install --upgrade https://storage.googleapis.com/tensorflow/linux/gpu/tensorflow-#{node.tensorflow.version}-cp27-none-linux_x86_64.whl

EOF
end


end
