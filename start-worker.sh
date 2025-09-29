#!/bin/bash

####################################################################################
# DO NOT MODIFY THE BELOW ##########################################################

/etc/init.d/ssh start
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/shared_rsa

# DO NOT MODIFY THE ABOVE ##########################################################
####################################################################################

# Start HDFS/Spark worker here
export HADOOP_HOME=/opt/hadoop-3.3.6
export SPARK_HOME=/opt/spark-3.4.1
export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$SPARK_HOME/bin:$SPARK_HOME/sbin
export JAVA_HOME=/usr/local/openjdk-8

# Wait a bit for main to be ready
sleep 10

# Start DataNode
echo "Starting DataNode..."
hdfs --daemon start datanode

# Wait a bit more for Spark Master to be ready
sleep 5

# Start Spark Worker
echo "Starting Spark Worker..."
$SPARK_HOME/sbin/start-worker.sh spark://main:7077

# Keep container running
bash