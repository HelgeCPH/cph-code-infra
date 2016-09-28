#!/bin/bash

BUILD_NUMBER=$1
DOCKER_ID=$2
# stop all running containers with our web application
docker stop `docker ps -a | grep ${DOCKER_ID}/glassfish-cph | awk '{print substr ($0, 0, 12)}'`
# remove all of those containers
docker rm `docker ps -a | grep ${DOCKER_ID}/glassfish-cph | awk '{print substr ($0, 0, 12)}'`
# get the newest version of the containerized web application and run it
docker pull ${DOCKER_ID}/glassfish-cph:${BUILD_NUMBER}
docker run -d -ti -p 4848:4848 -p 8080:8080 ${DOCKER_ID}/glassfish-cph:${BUILD_NUMBER}
