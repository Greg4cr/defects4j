#!/bin/bash
# Gregory Gay (greg@greggay.com)
# Initial installation setup for Amazon EC2 instances.
# Must be run in sudo mode.

# Install Java8
java_base_version="8"
java_sub_version="91"
java_base_build="14"

java_version="${java_base_version}u${java_sub_version}"
java_build="b${java_base_build}"
java_version_with_build="${java_version}-${java_build}"

wget --no-cookies --header "Cookie: gpw_e24=xxx; oraclelicense=accept-securebackup-cookie;" "http://download.oracle.com/otn-pub/java/jdk/${java_version_with_build}/jdk-${java_version}-linux-x64.rpm"
rpm -i jdk-${java_version}-linux-x64.rpm

#/usr/sbin/alternatives --install /usr/bin/java java /usr/java/jdk1.${java_base_version}.0_${java_sub_version}/bin/java 20000
export JAVA_HOME=/usr/java/default
cat "export JAVA_HOME=/usr/java/default" >> /home/ec2-user/.bashrc

# Ensure correct versions of Java are used
/usr/sbin/alternatives --config java
/usr/sbin/alternatives --config javac

# Install ant
wget http://archive.apache.org/dist/ant/binaries/apache-ant-1.9.0-bin.tar.gz
tar xzf apache-ant-1.9.0-bin.tar.gz
mv apache-ant-1.9.0 /usr/local/apache-ant
export ANT_HOME=/usr/local/apache-ant
echo 'export ANT_HOME=/usr/local/apache-ant' >> /home/ec2-user/bashrc
export PATH=$PATH:/usr/local/apache-ant/bin
echo 'export PATH=$PATH:/usr/local/apache-ant/bin' >> /home/ec2-user/bashrc

# Install other dependencies
yum install svn
yum install patch
yum install gcc
yum install cpan
cpan DBI
cpan DBD:CSV
