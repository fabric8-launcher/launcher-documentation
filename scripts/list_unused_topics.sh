#!/bin/bash
CURRENT_DIR="$( pwd -P)"
SCRIPT_SRC="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )"
TOPICS_SRC="$( dirname $SCRIPT_SRC )/docs/topics"
DOCS_SRC="$( dirname $SCRIPT_SRC )/docs"
SKIP="$SCRIPT_SRC/skip_unused_files.txt"

cd $DOCS_SRC
master_files_names=`find */master.adoc`

cd $TOPICS_SRC
topic_file_names=`ls *.adoc`

cd $DOCS_SRC
for name in $topic_file_names
do
  if [[ $(grep $name $SKIP) ]]; then
    echo "skipping $name" >> /dev/null;
  elif [[ $(grep $name */master.adoc) ]]; then
    echo "found in master!" >> /dev/null;
  elif [[ $(grep $name $TOPICS_SRC/*.adoc) ]]; then
    echo "found in topic!" >> /dev/null;
  else
    echo "$TOPICS_SRC/$name";
  fi
done