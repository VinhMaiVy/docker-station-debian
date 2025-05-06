#!/bin/bash
set -e
IMAGE=`cat docker.name`
DOCKERTAG=`cat docker.tag`
docker pull $DOCKERTAG/$IMAGE:latest
