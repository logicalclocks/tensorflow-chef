name             'tensorflow'
maintainer       "tensorflow"
maintainer_email "jdowling@kth.se"
license          "Apache v2.0"
description      'Installs/Configures/Runs tensorflow'
version          "0.1"

recipe            "tensorflow::install", "Experiment setup for tensorflow"
recipe            "tensorflow::default",  "configFile=; Experiment name: default"
recipe            "tensorflow::distributed",  "configFile=; Experiment name: distributed"
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


