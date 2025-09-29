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
RUN wget https://archive.apache.org/dist/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz && \
    tar -xzf hadoop-3.3.6.tar.gz -C /opt/ && \
    rm hadoop-3.3.6.tar.gz

# Set environment variables
ENV HADOOP_HOME=/opt/hadoop-3.3.6
ENV PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
ENV JAVA_HOME=/usr/local/openjdk-8

# Setup the core-site.xml, hdfs-site.xml and the workers file from predefined configs
COPY configuration/core-site.xml $HADOOP_HOME/etc/hadoop/core-site.xml
COPY configuration/hdfs-site.xml $HADOOP_HOME/etc/hadoop/hdfs-site.xml
COPY configuration/workers $HADOOP_HOME/etc/hadoop/workers