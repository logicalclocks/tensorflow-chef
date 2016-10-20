### Tensorflow Cookbook
Author: Jim Dowling

OS support: Ubuntu 16+, Centos 7+


Requirements for Vagrant installation: chefdk


##Vagrant Usage

Install chefdk (https://downloads.chef.io/chef-dk)

./run-vagrant.sh


## Karamel Usages


1. Create a project "tf"
2. upload tf.csv to tf/Resources in hdfs
3.
source $HADOOP_HOME/libexec/hadoop-config.sh
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$JAVA_HOME/jre/lib/amd64/server
CLASSPATH=$($HADOOP_HDFS_HOME/bin/hdfs classpath --glob) python test-read.py


To HDFS with TensorFlow, change the file paths you use to read and write
data to an HDFS path. For example:

filename_queue = tf.train.string_input_producer([
    "hdfs://namenode:8020/path/to/file1.csv",
    "hdfs://namonode:8020/path/to/file2.csv",
])
If you want to use the namenode specified in your HDFS configuration files, then
change the file prefix to hdfs://default/.

When launching your TensorFlow program, the following environment variables must
be set:

JAVA_HOME: The location of your Java installation.
HADOOP_HDFS_HOME: The location of your HDFS installation. You can also set this environment variable by running:
source $HADOOP_HOME/libexec/hadoop-config.sh
LD_LIBRARY_PATH: To include the path to libjvm.so. On Linux:
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$JAVA_HOME/jre/lib/amd64/server
CLASSPATH: The Hadoop jars must be added prior to running your TensorFlow program. The CLASSPATH set by $HADOOP_HOME/libexec/hadoop-config.sh is insufficient. Globs must be expanded as described in the libhdfs documentation:
CLASSPATH=$($HADOOP_HDFS_HOME/bin/hdfs classpath --glob) python your_script.py
