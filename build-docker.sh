#!/bin/bash
set -e
IMAGE=`cat docker.name`
DOCKERTAG=`cat docker.tag`
docker build -t $IMAGE --build-arg WEBUSERNAME=webuser .
#docker tag $IMAGE:latest $DOCKERTAG/$IMAGE:latest
docker image prune --force
