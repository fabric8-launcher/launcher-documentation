#!/bin/bash
docker build --force-rm -t docs:latest scripts/.

HOST_GIT_REPO_DIR="/path/to/documentation"
IMG_GIT_REPO_DIR="/documentation"

docker run -ti -p 8080:8080 -v $HOST_GIT_REPO_DIR:$IMG_GIT_REPO_DIR docs:latest /bin/bash -c 'cd '$IMG_GIT_REPO_DIR'; rm -r ci/openshiftio-appdev-docs/src/main/resources/webroot/docs/*; ./scripts/buildGuides.sh; mkdir -p ci/openshiftio-appdev-docs/src/main/resources/webroot; cp -r html/* ci/openshiftio-appdev-docs/src/main/resources/webroot/docs/; cd ci/openshiftio-appdev-docs; mvn clean compile vertx:run;'