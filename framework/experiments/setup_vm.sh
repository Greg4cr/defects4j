#!/bin/bash
# Gregory Gay (greg@greggay.com)
# Initial installation setup for local Ubuntu VM instances.
# Must be run in sudo mode.

# Install Java8

## Latest JDK8 version is JDK8u141 released on 19th July, 2017.

apt-get install rpm

BASE_URL_8=http://download.oracle.com/otn-pub/java/jdk/8u141-b15/336fa29ff2bb4ef291e347e091f7f4a7/jdk-8u141

platform="-linux-x64.rpm"

JDK_VERSION=`echo $BASE_URL_8 | rev | cut -d "/" -f1 | rev`

wget -c --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" "${BASE_URL_8}${platform}"

rpm -i ${JDK_VERSION}${platform}

echo "export JAVA_HOME=/usr/java/default" >> /home/greg/.bashrc

# Ensure correct versions of Java are used
/usr/sbin/alternatives --config java
/usr/sbin/alternatives --config javac

# Install ant
wget http://archive.apache.org/dist/ant/binaries/apache-ant-1.9.0-bin.tar.gz
tar xzf apache-ant-1.9.0-bin.tar.gz
mv apache-ant-1.9.0 /usr/local/apache-ant
echo 'export ANT_HOME=/usr/local/apache-ant' >> /home/greg/.bashrc
echo 'export PATH=$PATH:/usr/local/apache-ant/bin' >> /home/greg/.bashrc

# Install other dependencies
apt-get install make
apt-get install screen
apt-get install unzip
apt-get install git
#apt-get install svn
apt-get install patch
apt-get install gcc
#apt-get install cpan
cpan DBI
cpan DBD:CSV

# Set up SSH for file uploads
ssh-keygen -t rsa
cat ~/.ssh/id_rsa.pub | ssh bstech@blankslatetech.com "mkdir -p ~/.ssh && cat >>  ~/.ssh/authorized_keys"
