#!/usr/bin/env bash

SCRIPT_SRC="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )"           # Script source directory
TEMP_DIR="$(mktemp -d)"                                                     # Temporary directory, will be deleted

REPO_NAME="wildfly-swarm"                                                   # Repository base name, and the directory name on the disk
REPO_URL="https://github.com/wildfly-swarm/${REPO_NAME}.git"                # Repo Git URL
REPO_BRANCH="master"                                                        # Branch to be synchronized

FILES_LIST="${SCRIPT_SRC}/wildfly-swarm-files.txt"                          # File with file- or directory names to synchronize
FILES_DESTINATION="$(realpath ${SCRIPT_SRC}/../docs/topics/wildfly-swarm)"  # Destination directory in this repository where to sync

git rm $FILES_DESTINATION

echo "Cloning the WildFly Swarm repository..." >&2

set -e

pushd $TEMP_DIR &>/dev/null
git clone $REPO_URL --depth 1 --branch $REPO_BRANCH
cd $REPO_NAME/docs
mvn clean install -DskipTests -Dswarm.product.build
find -type d -name target -prune -exec rm -rf '{}' \;
popd &>/dev/null

echo "Copying files..." >&2

mkdir -p $FILES_DESTINATION 2>/dev/null
for line in $(cat $FILES_LIST); do
    printf "$line" | grep -q '^\W*$' && continue # Ignore empty lines
    printf "$line" | grep -q '^#' && continue # Ignore commented-out lines
    pushd $TEMP_DIR/$REPO_NAME &>/dev/null
    rsync -avhR $line $FILES_DESTINATION
    popd &>/dev/null
done

echo "Committing changes..." >&2

git add $FILES_DESTINATION
git commit $FILES_DESTINATION -m "Synced WildFly Swarm sources"

echo "Cleaning up..." >&2

rm -rf $TEMP_DIR

echo "Done." >&2

