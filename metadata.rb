name             "tensorflow"
maintainer       "Jim Dowling"
maintainer_email "jdowling@kth.se"
license          "Apache v2.0"
description      'Installs/Configures/Runs tensorflow'
version          "0.1.0"

recipe            "tensorflow::install", "Download and compile and install tensorflow"
recipe            "tensorflow::default",  "Setup tensorflow"
recipe            "tensorflow::distributed",  "Setup distributed tensorflow"
recipe            "tensorflow::purge",  "Uninstall tensorflow and cuda"


depends "kagent"
depends "java"
depends "magic_shell"
depends "ndb"
depends "hops"
depends "poise-python"

%w{ ubuntu debian rhel centos }.each do |os|
  supports os
end


attribute "tensorflow/user",
:description => "user parameter value",
:type => "string"

attribute "tensorflow/group",
:description => "group parameter value",
:type => "string"

attribute "tensorflow/dir",
:description => "Base installation directory",
:type => "string"

attribute "download_url",
:description => "url for binaries",
:type => "string"

attribute "tensorflow/git_url",
:description => "url for git sourcecode for tensorflow",
:type => "string"

attribute "cuda/accept_nvidia_download_terms",
:description => "Accept cuda licensing terms and conditions. Default: 'false'. Change to 'true' to enable cuda.",
:type => "string"

attribute "tensorflow/install",
:description => "'src' to compile/install from source code. 'dist' to install from binaries. ",
:type => "string"

