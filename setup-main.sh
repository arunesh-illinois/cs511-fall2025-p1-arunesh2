#!/bin/bash
export JAVA_HOME=/usr/local/openjdk-8/jre

####################################################################################
# DO NOT MODIFY THE BELOW ##########################################################

ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
chmod 0600 ~/.ssh/authorized_keys

# DO NOT MODIFY THE ABOVE ##########################################################
####################################################################################

# Setup HDFS/Spark main here
export HADOOP_HOME=/opt/hadoop-3.3.6
export SPARK_HOME=/opt/spark-3.4.1
export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$SPARK_HOME/bin:$SPARK_HOME/sbin

# Configure the hadoop environment by rechecking the openjdk-8
echo "export JAVA_HOME=/usr/local/openjdk-8" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh

# Create directories for NameNode and DataNode
mkdir -p /root/hdfs/namenode
mkdir -p /root/hdfs/datanode

# Make spark-env.sh executable
chmod +x $SPARK_HOME/conf/spark-env.sh

# Create Spark work and log directories
mkdir -p $SPARK_HOME/work
mkdir -p $SPARK_HOME/logs