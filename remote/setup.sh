#!/bin/bash

# Important, run this script as sudo

function create_homes() {

cat <<EOF
echo "You should not be running any containers in /opt/containers when you run this script."
echo "Removing old directory structure from /opt/containers"
rm /opt/containers/* -fr
echo "Re-creating directory structure inside /opt/containers"
mkdir -p /opt/containers/artifactory/data
mkdir -p /opt/containers/artifactory/logs
mkdir -p /opt/containers/artifactory/backup
mkdir -p /opt/containers/registry
echo "Changing ownership of /opt/containers to 1000:50 recursively"
chown 1000:50 /opt/containers -R
echo "Done."
EOF

}

function create_docker-compose() {

cat <<EOF
  apache:
    # Build from Dockerfile because we want to fix TimeZone as well as have httpd.conf and index.html cooked in it.
    build: apache/
    hostname: apache
    ports:
      - "80:80"
    volumes:
      # Fix time and timezone of the container.
      - /etc/localtime:/etc/localtime

  artifactory:
    image: mattgruter/artifactory:3.9.2
    hostname: artifactory
    ## build: artifactory/
    ports:
      - "8082:8080"
    volumes:
      - /etc/localtime:/etc/localtime
      - /artifactory/data
      - /artifactory/logs
      - /artifactory/backup
    environment:
      - JAVA_OPTS='-Djsse.enableSNIExtension=false'

  # registry:
  #   # Note: registry needs Docker daemon to run with: "-H tcp://127.0.0.1:2375 -H unix:///var/run/docker.sock --insecure-registry <REGISTRY_HOSTNAME>:5000"
  #   # Question: How do we know the name of REGISTRY_HOSTNAME in advance? or what value do I fill in there?
  #   # Build registry image from registry directory.
  #   # build: registry/
  #   image: registry:2
  #   hostname: registry
  #   ports:
  #     - "5000:5000"
  #   volumes:
  #     # For some strange reason Docker registry container stores the images in /tmp/registry .
  #     - /etc/localtime:/etc/localtime
  #     # Registry:2 uses /var/lib/registry for storage
  #     - /var/lib/registry
  # glassfish:
  #  image: glassfish/server
  #  hostname: glassfish
  #  ports:
  #    - "8083:8080"

EOF
}

sudo apt-get update
sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main" | sudo tee /etc/apt/sources.list.d/docker.list
sudo apt-get update
apt-cache policy docker-engine
sudo apt-get install -y docker-engine
sudo usermod -aG docker $(whoami)
sudo apt-get install -y docker-compose
create_docker-compose > docker-compose.yml
create_homes > create-homes.sh
chmod u+x ./create-homes.sh
sudo ./create-homes.sh

# Installing the deployment script, which we will call from a Jenkins build job
wget https://raw.githubusercontent.com/HelgeCPH/cph-code-infra/master/remote/deploy2.sh
chmod u+x ./deploy2.sh

# for the apache container we need the following files, which we download
# directly without cloning the repository
mkdir apache
cd apache
wget https://raw.githubusercontent.com/HelgeCPH/cph-code-infra/master/remote/apache/Dockerfile
wget https://raw.githubusercontent.com/HelgeCPH/cph-code-infra/master/remote/apache/httpd.conf
wget https://raw.githubusercontent.com/HelgeCPH/cph-code-infra/master/remote/apache/index.html
cd ..
sudo docker-compose up -d
