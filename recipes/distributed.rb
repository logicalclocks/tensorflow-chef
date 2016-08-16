
script 'run_experiment' do
  cwd "/tmp"
  user node['tensorflow']['user']
  group node['tensorflow']['group']
  interpreter "bash"
  code <<-EOM

  EOM
end

