#!/bin/bash
SCRIPT_SRC="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )"
TOPICS_SRC="$( dirname $SCRIPT_SRC )/docs/topics"
DOCS_SRC="$( dirname $SCRIPT_SRC )/docs"
SKIP="$SCRIPT_SRC/skip_unused_files.txt"

#handles spaces in files in for loop below. Forces for loop to use newlines as separators
SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

pushd $DOCS_SRC >> /dev/null;
master_files_names=`ls -1 */master.adoc`

pushd $TOPICS_SRC >> /dev/null;
topic_file_names=`ls -1 *.adoc`

pushd $DOCS_SRC >> /dev/null;

for name in $topic_file_names
do
  if grep -q $name $SKIP; then
    echo "skipping $name" >> /dev/null;
  elif grep -q $name */master.adoc; then
    echo "found in master!" >> /dev/null;
  elif grep -q $name $TOPICS_SRC/*.adoc; then
    echo "found in topic!" >> /dev/null;
  else
    echo "$TOPICS_SRC/$name";
  fi
done