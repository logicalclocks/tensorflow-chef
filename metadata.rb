name             "tensorflow"
maintainer       "Jim Dowling"
maintainer_email "jdowling@kth.se"
license          "Apache v2.0"
description      'Installs/Configures/Runs tensorflow'
version          "3.5.0"

recipe            "tensorflow::install", "Install NVIDIA or AMD drivers"
recipe            "tensorflow::default",  "Upload Hopsworks tour examples"


depends "java", '~> 7.0.0'
depends "magic_shell", '~> 1.0.0'
depends 'apt', '~> 7.2.0'
depends 'kagent'
depends 'ndb'
depends 'hops'
depends 'conda'

%w{ ubuntu debian rhel centos }.each do |os|
  supports os
end

attribute "download_url",
          :description => "url for binaries",
          :type => "string"

attribute "install/dir",
          :description => "Set to a base directory under which we will install.",
          :type => "string"

attribute "install/user",
          :description => "User to install the services as",
          :type => "string"

#
# Nvidia
#

attribute "nvidia/driver_version",
          :description => "NVIDIA driver version to use",
          :type => "string"

attribute "cuda/accept_nvidia_download_terms",
          :description => "Accept cuda licensing terms and conditions. Default: 'false'. Change to 'true' to enable cuda.",
          :type => "string"

attribute "cuda/skip_test",
          :description => "Dont check if there is a local nvidia card on this machine",
          :type => "string"

attribute "cuda/skip_stop_xserver",
          :description => "Dont restart the xserver (probably a localhost installation)",
          :type => "string"

#
#
# Python library versions
#
#
attribute "tensorflow/version",
          :description => "tensorflow and tensorflow-gpu version to install in python base environments",
          :type => "string"
