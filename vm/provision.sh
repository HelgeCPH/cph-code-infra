#!/bin/bash

# add this line to hosts too get rid of unknown host messages
# echo '127.0.1.1 ubuntu-xenial' | sudo tee --append /etc/hosts

# install Jenkins to the VM
wget -q -O - https://pkg.jenkins.io/debian/jenkins-ci.org.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt-get update
sudo apt-get install -y jenkins
# we need the JDK to build our code later
sudo apt-get install -y openjdk-8-jdk

# install docker to the VM so that we can build docker images
sudo apt-get update
sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main" | sudo tee /etc/apt/sources.list.d/docker.list
sudo apt-get update
apt-cache policy docker-engine
sudo apt-get install -y docker-engine

# add the users to the docker group, so that we can run the docker commands
# without sudo. Be carefull with that on a real machine as docker commands can
# execute root level commands when building the images. Should be okay on a VM.
sudo usermod -aG docker $(whoami)
sudo usermod -aG docker jenkins
sudo systemctl daemon-reload
sudo systemctl restart docker
sudo service jenkins restart

# Your need this password to complete the initial Jenkins setup on the VM
echo "********** Initial Admin Password **********"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
echo "********************************************"
