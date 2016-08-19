
Vagrant.configure("2") do |c|
  if Vagrant.has_plugin?("vagrant-omnibus")
#    require 'vagrant-omnibus'
    c.omnibus.chef_version = "12.4.3"
  end
  if Vagrant.has_plugin?("vagrant-cachier")
    c.omnibus.cache_packages = true        
    c.cache.scope = :machine
    c.cache.auto_detect = false
    c.cache.enable :apt
    c.cache.enable :gem    
  end
#  c.vm.synced_folder "/srv/hops-downloads", "/srv/hops-downloads"
#  c.vm.box = "opscode-ubuntu-16.04"
  #c.vm.box_url = "https://atlas.hashicorp.com/ubuntu/boxes/trusty64/versions/20150924.0.0/providers/virtualbox.box"
  c.vm.box = "bento/ubuntu-16.04"
  #c.vm.hostname = "default-ubuntu-1604.vagrantup.com"

  c.vm.provider :virtualbox do |p|
    p.customize ["modifyvm", :id, "--memory", "8500"]
    p.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    p.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
    p.customize ["modifyvm", :id, "--nictype1", "virtio"]
    p.customize ["modifyvm", :id, "--cpus", "2"]   
  end


   c.vm.provision :chef_solo do |chef|
     chef.cookbooks_path = "cookbooks"
     chef.json = {
     "ntp" => {
          "install" => "true"
     },
     "public_ips" => ["10.0.2.15"],
     "private_ips" => ["10.0.2.15"],
     "tensorflow" => {
	  "default" =>      { 
   	  	       "private_ips" => ["10.0.2.15"]
	       },
     },
     "vagrant" => "true",
     }

     chef.add_recipe "kagent::install"
     chef.add_recipe "tensorflow::install"
     chef.add_recipe "tensorflow::default"
  end 

end

