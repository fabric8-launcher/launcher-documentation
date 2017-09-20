#!/usr/bin/env bash

BUILDER_IMAGE="appdev-documentation-builder"
BUILDER_CONT="appdev-documentation-builder-container"
DEPLOY_IMAGE="appdev-documentation-deploy"
TARGET_DIR="html"

# Exit on error
set -e

#[ -f jenkins-env ] && cat jenkins-env | grep -e PASS -e GIT_COMMIT -e DEVSHIFT > inherit-env
#[ -f inherit-env ] && . inherit-env

# We need to disable selinux for now, XXX
/usr/sbin/setenforce 0

# Get all the deps in
yum -y install docker make git

# Get all the deps in
yum -y install docker make git
service docker start

#BUILD
docker build -t ${BUILDER_IMAGE} -f Dockerfile.build .

mkdir ${TARGET_DIR}/
mkdir ${TARGET_DIR}/images

docker run --detach=true --name ${BUILDER_CONT} -t -v $(pwd)/${TARGET_DIR}:/${TARGET_DIR}:Z ${BUILDER_IMAGE} /bin/tail -f /dev/null #FIXME

docker exec ${BUILDER_CONT} sh scripts/build_guides.sh

#Need to do this again to set permission of images and html files
chmod -R 0777 ${TARGET_DIR}/

#BUILD DEPLOY IMAGE
docker build -t ${DEPLOY_IMAGE} -f Dockerfile.deploy .
