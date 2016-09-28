# Start Bugfix: https://github.com/berkshelf/berkshelf-api/issues/112
Encoding.default_external = "UTF-8"
# End Bugfix

source 'https://supermarket.chef.io'

cookbook 'kagent', github: 'karamelchef/kagent-chef', branch: 'master'
metadata

cookbook 'java'
cookbook 'bazel', github: 'gengo/cookbook-bazel', branch: 'master'
cookbook 'magic_shell'
cookbook 'build-essential'
cookbook 'poise-python'
cookbook 'zip'
cookbook 'apt'
cookbook 'homebrew'
cookbook 'ndb', github: "hopshadoop/ndb-chef", branch: "master"
cookbook 'apache_hadoop', github: "hopshadoop/apache-hadoop-chef", branch: "master"
cookbook 'hops', github: "hopshadoop/hops-hadoop-chef", branch: "spark_2.0"
cookbook 'poise-python', '~> 1.4.0'