#!/bin/bash
set -e
IMAGE=`cat docker.name`
DOCKERTAG=`cat docker.tag`
#docker logout
#docker login
docker push $DOCKERTAG/$IMAGE:latest
