#!/bin/bash
echo Starting preview server... >&2
echo Root Access is needed for building the Docker image with the server. >&2

sudo docker build --force-rm -t docs:latest scripts/.

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
HOST_GIT_REPO_DIR=$(dirname $DIR)
IMG_GIT_REPO_DIR="/documentation"

sudo docker run -ti -p 8080:8080 --privileged -v $HOME/.m2:/root/.m2 -v $HOST_GIT_REPO_DIR:$IMG_GIT_REPO_DIR docs:latest /bin/bash -c 'cd '$IMG_GIT_REPO_DIR'; rm -r ci/openshiftio-appdev-docs/src/main/resources/webroot/docs/*; ./scripts/buildGuides.sh; mkdir -p ci/openshiftio-appdev-docs/src/main/resources/webroot; cp -r html/* ci/openshiftio-appdev-docs/src/main/resources/webroot/docs/; cd ci/openshiftio-appdev-docs; mvn clean compile vertx:run;'
