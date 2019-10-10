#!/usr/bin/env bash

SCRIPT_SRC="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )"           # Script source directory
TEMP_DIR="$(mktemp -d)"                                                     # Temporary directory, will be deleted

REPO_NAME="thorntail"                                                   # Repository base name, and the directory name on the disk
REPO_URL="git@gitlab.cee.redhat.com:thorntail-prod/${REPO_NAME}.git"               # Repo Git URL
REPO_BRANCH="2.5.x"                                                         # Branch to be synchronized
MAVEN_SETTINGS_URL="https://gitlab.cee.redhat.com/thorntail-prod/thorntail/blob/$REPO_BRANCH/boms/src/main/resources/custom-settings.xml" # Maven settings to use when building

FILES_LIST="${SCRIPT_SRC}/files-to-sync.txt"                          # File with file- or directory names to synchronize
FILES_DESTINATION="$(realpath ${SCRIPT_SRC}/../../docs/topics/thorntail)"  # Destination directory in this repository where to sync

# Testing whether the Maven config file was provided
if [ $# -lt 1 ]; then
    echo "Usage: sync.sh PATH_TO_MAVEN_SETTINGS

Please provide the path to the Maven settings file.
The file can be downloaded from $MAVEN_SETTINGS_URL."
    exit 1
fi

maven_settings_file="$(realpath $1)"

# Testing whether the Maven config file provided exists
if ! test -f $maven_settings_file; then
    echo "The \'$maven_settings_file\' file provided does not exist. Please provide a valid path.

The file can be downloaded from $MAVEN_SETTINGS_URL."
    exit 1
fi

# Testing if all required programs are present
for binary in mvn git; do
    if ! $binary --version &>/dev/null; then
        echo "The $binary binary is missing, please install it." 1>&2
        exit 127
    fi
done

git rm -r $FILES_DESTINATION

echo "Cloning the Thorntail repository..." >&2

set -e

pushd $TEMP_DIR &>/dev/null
git clone $REPO_URL --depth 1 --branch $REPO_BRANCH
cd $REPO_NAME

# Store a commit hash into a file
git rev-parse HEAD > docs/commit.hash

# Generate product fractions reference
# WORKAROUND for ENTSWM-458: -Dswarm.docs.skip
./release/run-pme.sh
mvn clean install -DskipTests -Denforcer.skip -Dswarm.docs.skip -Dswarm.product.build -s $maven_settings_file
cd docs
mvn generate-resources -DskipTests -Denforcer.skip -Dswarm.docs.skip -Dswarm.product.build -s $maven_settings_file

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
git commit $FILES_DESTINATION -m "Synced Thorntail sources"

echo "Cleaning up..." >&2

rm -rf $TEMP_DIR

echo "Done." >&2
