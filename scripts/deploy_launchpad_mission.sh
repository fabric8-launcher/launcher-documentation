#!/usr/bin/env bash

# Goal of the script :
# 1) Deploy Launchpad mission control template using the parameters passed to authenticate the user,
# 2) Setup the Github identity (account & token) &
# 3) Patch jenkins to use admin as role
#
# Command to be used
# ./deploy_launchpad.sh -p projectName -i username:password -g myGithubUser:myGithubToken OR
# ./deploy_launchpad.sh -p projectName -t myOpenShiftToken -g myGithubUser:myGithubToken
#

# Set Default values
PROJECTNAME="myproject"
id="developer:developer"

while getopts p:g:t:i: option
do
        case "${option}"
        in
                p) PROJECTNAME=${OPTARG};;
                g) github=${OPTARG};;
                i) id=${OPTARG};;
                t) TOKEN=${OPTARG};;
        esac
done

VERSION="v2"
CONSOLE_URL=$(minishift console --url)
IFS=':' read -a IDENTITY <<< "$id"
IFS=':' read -a GITHUB_IDENTITY <<< "$github"
HOSTNAMEORIP=$(echo $CONSOLE_URL | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}")

echo "-----------------Parameters -------------------------"
echo "Host: $HOSTNAMEORIP"
echo "Project: $PROJECTNAME"
echo "Console: $CONSOLE_URL"
echo "Github user: ${GITHUB_IDENTITY[0]}"
echo "Github token: ${GITHUB_IDENTITY[1]}"
echo "Identity: ${IDENTITY[0]}, ${IDENTITY[1]}"
echo "------------------------------------------"

echo "------------------- Log on to OpenShift Platform -----------------------"
if [ "$TOKEN" != "" ]; then
   oc login $CONSOLE_URL --token=$TOKEN
else
   echo "oc login $CONSOLE_URL -u ${IDENTITY[0]} -p ${IDENTITY[1]}"
   oc login $CONSOLE_URL -u ${IDENTITY[0]} -p ${IDENTITY[1]}
fi
echo "------------------------------------------"

# Create Project where launchpad-mission control will be deployed
echo "------------------ Create New Project ----------------------"
oc new-project $PROJECTNAME
echo "------------------------------------------"

# Install the launchpad-missioncontrol template
echo "----------------- Install Launchpad template --------------------"
oc create -n $PROJECTNAME -f https://raw.githubusercontent.com/openshiftio/launchpad-templates/$VERSION/openshift/launchpad-template.yaml
echo "------------------------------------------"

# Local Deployment of Launchpad
# -p LAUNCHPAD_MISSIONCONTROL_OPENSHIFT_API_URL=https://openshift.default.svc.cluster.local
# -p LAUNCHPAD_KEYCLOAK_URL=https://sso.prod-preview.openshift.io/auth \
# -p LAUNCHPAD_KEYCLOAK_REALM=fabric8 \
echo "------------------ Create launch pad mission application ---------------------"
oc new-app launchpad -n $PROJECTNAME \
    -p LAUNCHPAD_MISSIONCONTROL_GITHUB_USERNAME=$GITHUB_IDENTITY[0] \
    -p LAUNCHPAD_MISSIONCONTROL_GITHUB_TOKEN=$GITHUB_IDENTITY[1] \
    -p LAUNCHPAD_MISSIONCONTROL_OPENSHIFT_CONSOLE_URL=$CONSOLE_URL \
    -p LAUNCHPAD_MISSIONCONTROL_OPENSHIFT_API_URL=$CONSOLE_URL \
    -p LAUNCHPAD_KEYCLOAK_URL= \
    -p LAUNCHPAD_KEYCLOAK_REALM= \
    -p LAUNCHPAD_MISSIONCONTROL_OPENSHIFT_USERNAME=$IDENTITY[0] \
    -p LAUNCHPAD_MISSIONCONTROL_OPENSHIFT_PASSWORD=$IDENTITY[1] \
    -p LAUNCHPAD_BACKEND_CATALOG_GIT_REPOSITORY=https://github.com/openshiftio/booster-catalog.git \
    -p LAUNCHPAD_BACKEND_CATALOG_GIT_REF=master \
    -p LAUNCHPAD_BACKEND_CATALOG_INDEX_PERIOD="0" \
    -p LAUNCHPAD_FRONTEND_HOST=launchpad-frontend-$PROJECTNAME.$HOSTNAMEORIP.nip.io
echo "------------------------------------------"
#
# Replace edit role with admin in order to allow the jenkins serviceaccount to by example create rolebindings, ...
# Log on to the platform using system:admin user
#
echo "------------------ Patch Jenkins to have admin role ------------------------"
oc login -u system:admin
oc patch template/jenkins-ephemeral -n openshift --type='json' -p='[{"op": "replace", "path": "/objects/3/roleRef/name", "value":"admin"}]'
echo "------------------------------------------"