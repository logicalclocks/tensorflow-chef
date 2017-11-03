case node["platform_family"]
when "debian"
  libs=%w{build-essential curl libcurl3-dev git libfreetype6-dev libpng12-dev libzmq3-dev pkg-config python-dev python-numpy python-pip software-properties-common swig zip zlib1g-dev }
                                                                                                                                                                                                                                                     
for lib in libs
  package lib do
    action :install
  end
end 


    bash "install-tfserving-prerequisities" do
      user "root"
      code <<-EOF
       set -e
       echo "deb [arch=amd64] http://storage.googleapis.com/tensorflow-serving-apt stable tensorflow-model-server tensorflow-model-server-universal" | sudo tee /etc/apt/sources.list.d/tensorflow-serving.list
       curl https://storage.googleapis.com/tensorflow-serving-apt/tensorflow-serving.release.pub.gpg | sudo apt-key add -
       apt-get update
       apt-get install tensorflow-model-server
    EOF
      not_if "which tensorflow_model_server"
    end


when "rhel"
  libs=%w{build-essential curl libcurl3-devel git libfreetype6-devel libpng12-devel libzmq3-devel pkg-config python-devel python-numpy python-pip software-properties-common swig zip zlib1g-devel }
end
    
