####################################################################################
# DO NOT MODIFY THE BELOW ##########################################################

FROM openjdk:8

RUN apt update && \
    apt upgrade --yes && \
    apt install ssh openssh-server --yes

# Setup common SSH key.
RUN ssh-keygen -t rsa -P '' -f ~/.ssh/shared_rsa -C common && \
    cat ~/.ssh/shared_rsa.pub >> ~/.ssh/authorized_keys && \
    chmod 0600 ~/.ssh/authorized_keys

# DO NOT MODIFY THE ABOVE ##########################################################
####################################################################################

# Install wget if not present
RUN apt install wget -y

# Setup HDFS/Spark resources here
# Setup Hadoop-3.3.6 as per requirement doc
RUN wget https://archive.apache.org/dist/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz && \
    tar -xzf hadoop-3.3.6.tar.gz -C /opt/ && \
    rm hadoop-3.3.6.tar.gz

# Setup Spark-3.4.1 as per requirement doc
RUN wget https://archive.apache.org/dist/spark/spark-3.4.1/spark-3.4.1-bin-hadoop3.tgz && \
    tar -xzf spark-3.4.1-bin-hadoop3.tgz -C /opt/ && \
    mv /opt/spark-3.4.1-bin-hadoop3 /opt/spark-3.4.1 && \
    rm spark-3.4.1-bin-hadoop3.tgz

# Install SBT for Scala compilation
RUN echo "deb https://repo.scala-sbt.org/scalasbt/debian all main" | tee /etc/apt/sources.list.d/sbt.list && \
    echo "deb https://repo.scala-sbt.org/scalasbt/debian /" | tee /etc/apt/sources.list.d/sbt_old.list && \
    curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823" | apt-key add && \
    apt update && \
    apt install sbt -y
# Set environment variables for Hadoop/Spark
ENV HADOOP_HOME=/opt/hadoop-3.3.6
ENV SPARK_HOME=/opt/spark-3.4.1
ENV PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$SPARK_HOME/bin:$SPARK_HOME/sbin
ENV JAVA_HOME=/usr/local/openjdk-8

# Setup the core-site.xml, hdfs-site.xml and the workers file from predefined configs for Hadoop
COPY configuration/core-site.xml $HADOOP_HOME/etc/hadoop/core-site.xml
COPY configuration/hdfs-site.xml $HADOOP_HOME/etc/hadoop/hdfs-site.xml
COPY configuration/workers $HADOOP_HOME/etc/hadoop/workers

# Setup the spark-default.conf, spark-env.sh and workers for Spark
COPY configuration/sparks-default.conf $SPARK_HOME/conf/spark-defaults.conf
COPY configuration/spark-env-setup.sh $SPARK_HOME/conf/spark-env.sh
COPY configuration/workers $SPARK_HOME/conf/slaves

# Scala copy for sorting
COPY scala_sorting opt/sorting