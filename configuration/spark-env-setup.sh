#!/usr/bin/env bash

export JAVA_HOME=/usr/local/openjdk-8
export HADOOP_HOME=/opt/hadoop-3.3.6
export SPARK_HOME=/opt/spark-3.4.1
export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
export SPARK_DIST_CLASSPATH=$($HADOOP_HOME/bin/hadoop classpath)
export SPARK_MASTER_HOST=main
export SPARK_MASTER_PORT=7077
export SPARK_MASTER_WEBUI_PORT=8080
export SPARK_WORKER_WEBUI_PORT=8081