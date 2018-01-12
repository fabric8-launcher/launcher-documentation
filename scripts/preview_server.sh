#!/usr/bin/env bash

SCRIPT_SRC="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )"

pushd $SCRIPT_SRC/.. &>/dev/null
if [[ $(id -u) -ne 0 ]]; then
    sudo CICO_LOCAL=true $SCRIPT_SRC/../cico_build_deploy.sh && sudo docker run -p 80:8080 -it launcher-documentation-deploy:latest
else
    CICO_LOCAL=true $SCRIPT_SRC/../cico_build_deploy.sh && docker run -p 80:8080 -it launcher-documentation-deploy:latest
fi
popd &>/dev/null

