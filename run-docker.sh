#! /bin/bash
set -e

IMAGE=`cat docker.name`
WEBPORT=2443
SSHPORT=2022
GEOMETRY=1920x1080
TODAY=$(date +'%Y%m%d')
CURRENT_RUNNING=$(docker container ls | grep -i $IMAGE | awk '{print $1}')

# Stop, save and commit current running container
if [ ! -z "$CURRENT_RUNNING" ]
then
	docker stop $CURRENT_RUNNING 
	docker commit $CURRENT_RUNNING $IMAGE.$TODAY
	docker rm $CURRENT_RUNNING 
fi

#Start new container
docker run -d --name $IMAGE -p $WEBPORT:443 -p $SSHPORT:22 -e GEOMETRY=$GEOMETRY -h $IMAGE $IMAGE:latest
