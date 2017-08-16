#!/bin/bash

GUIDE_NAME=$1

#This saves where the user currently is
HOME=`pwd`

#This changes you to the root of the project, ensuring the script runs consistently
cd `dirname $0`/..

mkdir docs/$GUIDE_NAME

#Go into guide dir we just created
cd docs/$GUIDE_NAME/

#Add template files to get things started
cp ../topics/templates/master.adoc .
cp ../topics/templates/build_guide.sh .
ln -s ../topics topics

#Update buildscript to build the guide we just created
echo -e "GUIDE_HTML_NAME="$GUIDE_NAME".html\n$(cat build_guide.sh)" > build_guide.sh
chmod +x build_guide.sh

#go back to where user was
cd $HOME
