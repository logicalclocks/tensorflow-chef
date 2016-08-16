bash "uninstall_cuda" do
    user "root"
    code <<-EOF
    set -e
    cd #{Chef::Config[:file_cache_path]}
    ./#{base_cuda_file} --silent --uninstall
    rm -f #{node.cuda.base_dir}
EOF
  only_if { ::File.exists?( "#{node.cuda.version_dir}" ) }
end
