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
depends "bazel"
depends "magic_shell"


%w{ ubuntu debian rhel centos }.each do |os|
  supports os
end



attribute "tensorflow/group",
:description => "group parameter value",
:type => "string"

attribute "tensorflow/user",
:description => "user parameter value",
:type => "string"


