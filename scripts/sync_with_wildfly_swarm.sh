#!/usr/bin/env bash

SCRIPT_SRC="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )"           # Script source directory
TEMP_DIR="$(mktemp -d)"                                                     # Temporary directory, will be deleted

REPO_NAME="wildfly-swarm"                                                   # Repository base name, and the directory name on the disk
REPO_URL="https://github.com/wildfly-swarm/${REPO_NAME}.git"                # Repo Git URL
REPO_BRANCH="master"                                                        # Branch to be synchronized

FILES_LIST="${SCRIPT_SRC}/wildfly-swarm-files.txt"                          # File with file- or directory names to synchronize
FILES_DESTINATION="$(realpath ${SCRIPT_SRC}/../docs/topics/wildfly-swarm)"  # Destination directory in this repository where to sync

git rm -r $FILES_DESTINATION

echo "Cloning the WildFly Swarm repository..." >&2

set -e

pushd $TEMP_DIR &>/dev/null
git clone $REPO_URL --depth 1 --branch $REPO_BRANCH
cd $REPO_NAME/docs

# Generate product fractions reference
mvn generate-resources -DskipTests -Dswarm.product.build
mv reference/index{,-product}.adoc

# Generate community fractions reference.
#
# We do not care that the some fractions are overwritten as they are always the
# same files for community and product, only the reference/index.adoc file
# changes.
mvn generate-resources -DskipTests
mv reference/index{,-community}.adoc

# Remove unwanted files
rm reference/.gitignore # Prevents the reference directory from being included in the RHOAR build
find -type d -name target -prune -exec rm -rf '{}' \;

popd &>/dev/null

echo "Copying files..." >&2

mkdir -p $FILES_DESTINATION 2>/dev/null
while read line; do
    printf "$line" | grep -q '^\W*$' && continue # Ignore empty lines
    printf "$line" | grep -q '^#' && continue # Ignore commented-out lines
    pushd $TEMP_DIR/$REPO_NAME &>/dev/null
    rsync -avhR $line $FILES_DESTINATION
    popd &>/dev/null
done < $FILES_LIST

echo "Committing changes..." >&2

git add $FILES_DESTINATION
git commit $FILES_DESTINATION -m "Synced WildFly Swarm sources"

echo "Cleaning up..." >&2

rm -rf $TEMP_DIR

echo "Done." >&2

