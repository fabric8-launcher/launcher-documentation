CURRENT_DIR="$( pwd -P)"
SCRIPT_SRC="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )"
DOCS_SRC="$( dirname $SCRIPT_SRC )/docs"
BUILD_RESULTS="Build Results:"
BUILD_MESSAGE=$BUILD_RESULTS

# Move to docs dir
cd $DOCS_SRC

echo "=== Building all the guides ==="
# Recurse through the guide directories and build them.
subdirs=`find . -maxdepth 1 -type d ! -iname ".*" ! -iname "topics" | sort`

echo $PWD
for subdir in $subdirs
do
  echo "Building $DOCS_SRC/${subdir##*/}"
  # Navigate to the dirctory and build it
  if ! [ -e $DOCS_SRC/${subdir##*/} ]; then
    BUILD_MESSAGE="$BUILD_MESSAGE\nERROR: $DOCS_SRC/${subdir##*/} does not exist."
    continue
  fi
  cd $DOCS_SRC/${subdir##*/}
  GUIDE_NAME=${PWD##*/}
  ./buildGuide.sh
  if [ "$?" = "1" ]; then
    BUILD_ERROR="ERROR: Build of $GUIDE_NAME failed. See the log above for details."
    BUILD_MESSAGE="$BUILD_MESSAGE\n$BUILD_ERROR"
  fi
  # Return to the parent directory
  cd $SCRIPT_SRC
done

# Return to where we started as a courtesy.
cd $CURRENT_DIR