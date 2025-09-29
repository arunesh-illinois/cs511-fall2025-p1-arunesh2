#!/bin/bash

####################################################################################
# DO NOT MODIFY THE BELOW ##########################################################

# Exchange SSH keys.
/etc/init.d/ssh start
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/shared_rsa
ssh-copy-id -i ~/.ssh/id_rsa -o 'IdentityFile ~/.ssh/shared_rsa' -o StrictHostKeyChecking=no -f worker1
ssh-copy-id -i ~/.ssh/id_rsa -o 'IdentityFile ~/.ssh/shared_rsa' -o StrictHostKeyChecking=no -f worker2

# DO NOT MODIFY THE ABOVE ##########################################################
####################################################################################

# Start HDFS/Spark main here
export HADOOP_HOME=/opt/hadoop-3.3.6
export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
export JAVA_HOME=/usr/local/openjdk-8

# Format NameNode only if not already formatted
if [ ! -d "/root/hdfs/namenode/current" ]; then
    echo "Formatting NameNode..."
    hdfs namenode -format -force
fi

# Start NameNode
echo "Starting NameNode..."
hdfs --daemon start namenode

# Wait for NameNode to be ready
sleep 5

# Start DataNode on main
echo "Starting DataNode on main..."
hdfs --daemon start datanode

# Keep container running
bash
