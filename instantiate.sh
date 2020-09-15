#!/bin/bash

# Execute : 
#      $ ./instantiate.sh  \
#           my-api-name \
#           07ac71-97cb-46c0-ad91-105eb78e8 \
#           myBusinessGroupName \
#           git@github:user/repository.git \  
#           maven-settings-id \
#           eu1.anypoint.mulesoft.com \
#           eu-central-1 

# This script executes the following steps:
# 1. Creates a new project in the parent folder where this template is located
#
# 2. Rename files by replacing "template-api" by your
#    API's name.
#
# 3. In all files' content replace "template-api" by
#    your API's name.
#
# 4. Rename root directory to new API name
#
# 5. Initializes the git configuration. 
#    If you don't supply the git repo you need to 
#        1. update the pom.xml yourself with the repo url inside <developerConnection></developerConnection>
#        2. execute : git remote set-url origin <repo-url> 
#
# You call it in the root directory of the repository and pass as the
# sole argument your API's name:
#

# Do not allow undefined variables.
set -u


print_help () {
    echo
    echo "Usage: ./instantiate.sh [api-name] [group-id] [group-name] [api-repo-url] [maven-settings-id] [anypoint-host] [region]"
    echo
    echo "Options:"
    echo "api-name (required): the name of the project"
    echo "group-id: the business group id."
    echo "group-name: the business group name."
    echo "api-repo-url: the url to the repo. default empty"
    echo "maven-settings-id: the id of the maven global settings that will be used in the jenkins pipeline. default -> maven-global-settings"
    echo "anypoint-host: the anypoint host. default -> anypoint.mulesoft.com"
    echo "region: the cloudhub region. default -> us-east-1"
    echo
}

print_git_repo_missing () {
    echo
    echo " ______________________________________________________________________________________________________"
    echo "| !! Git Repository manual configuration !!"
    echo "| * Please reconfigure your git remote address using: git remote set-url origin <repo-url>"
    echo "| * Make sure to update the repo url in the pom.xml inside <developerConnection></developerConnection>"
    echo "|______________________________________________________________________________________________________"
    echo
}

print_group_id_missing () {
    echo
    echo " ______________________________________________________________________________________________________"
    echo "| !! Group ID manual configuration !!"
    echo "| * Don't forget to update the groupId in your pom.xml file"
    echo "|______________________________________________________________________________________________________"
    echo
}

print_group_name_missing () {
    echo
    echo " ______________________________________________________________________________________________________"
    echo "| !! Group Name manual configuration !!"
    echo "| * Don't forget to update the ANYPOINT_BUSINESS_GROUP variable in your Jenkinsfile file"
    echo "|______________________________________________________________________________________________________"
    echo
}

COLOR_GREEN="$(tput setaf 2)"
COLOR_REST="$(tput sgr0)"


# We need the script's name in order to exclude it from searches.
SCRIPT_NAME=$(basename "$0")

# This is the template name, to be replaced in file names and file
# content.
OLD_ROOT=$(basename "$PWD")
TEMPLATE_FLAG="template-api" 

#---------- PARAMETERS ---------------------------------------------------

if [ "$#" -lt 1 ]; then
    print_help
    echo "[Error] You must specify at least the API Name."
    exit 1
fi

# API name.
NEW_ROOT="$1"

#BUSINESS_GROUP_ID 
if [ "$#" -gt 1 ]; then
    GROUP_ID="$2"
else
    GROUP_ID=""
fi

#BUSINESS GROUP NAME
if [ "$#" -gt 2 ]; then
    GROUP_NAME="$3"
else
    GROUP_NAME=""
fi

#API Repository
if [ "$#" -gt 3 ]; then
    REPO_URL="$4"
else
    REPO_URL=""
fi

#MAVEN GLOBAL SETTINGS ID
if [ "$#" -gt 4 ]; then
    MVN_GLBL_SETT_ID="$5"
else
    MVN_GLBL_SETT_ID="maven-global-settings"
fi

#ANYPOINT HOST
if [ "$#" -gt 5 ]; then
    ANYPOINT_HOST="$6"
else
    ANYPOINT_HOST="anypoint.mulesoft.com"
fi

#REGION
if [ "$#" -gt 6 ]; then
    REGION="$7"
else
    REGION="us-east-1"
fi


if [ -d "../$NEW_ROOT" ]; then
    print_help
    echo "[Error] \"$NEW_ROOT\" Directory exists. Please provide another name or remove the existing."
    exit 1
fi

#-------------------------------------------------------------------------------

echo;echo "Clone begin."


echo;echo "#### STEP1: COPY PROJECT"
# Create root directory by copying this template
echo -n "* Create new folder ../$OLD_ROOT -> ../$NEW_ROOT ... "
cp -r "../$OLD_ROOT" "../$NEW_ROOT"
cd "../$NEW_ROOT"
printf '%s%s%s\n' $COLOR_GREEN 'done' $COLOR_REST

echo;echo "#### STEP2: CUSTOMIZING PROJECT"

echo;echo "############### PROJECT NAME UPDATE"
# Rename files by replacing the project name.
while IFS= read -r -d '' old_name; do
    new_name="${old_name//$TEMPLATE_FLAG/$NEW_ROOT}"
    echo -n "* Renaming $old_name -> $new_name... "
    mv "$old_name" "$new_name"
    printf '%s%s%s\n' $COLOR_GREEN 'done' $COLOR_REST
done < <(find ./src -not -path "*/.git*" -type f -name "*${TEMPLATE_FLAG}*" -print0)

# Replace project name in src/, pom and README files
echo -n "* Replacing project name everywhere... "
find ./src -type f -print0 | LC_CTYPE=C xargs -0 sed -i '' s/"$OLD_ROOT"/"$NEW_ROOT"/g
find ./src -type f -print0 | LC_CTYPE=C xargs -0 sed -i '' s/"$TEMPLATE_FLAG"/"$NEW_ROOT"/g
find pom.xml -type f -print0 | LC_CTYPE=C xargs -0 sed -i '' s/"$OLD_ROOT"/"$NEW_ROOT"/g
find pom.xml -type f -print0 | LC_CTYPE=C xargs -0 sed -i '' s/"$TEMPLATE_FLAG"/"$NEW_ROOT"/g
find README.md -type f -print0 | LC_CTYPE=C xargs -0 sed -i '' s/"$OLD_ROOT"/"$NEW_ROOT"/g
find README.md -type f -print0 | LC_CTYPE=C xargs -0 sed -i '' s/"$TEMPLATE_FLAG"/"$NEW_ROOT"/g
printf '%s%s%s\n' $COLOR_GREEN 'done' $COLOR_REST

echo -n "* Updating APIKIT Router configuration name... "
find src/main/mule/global.xml  -type f -print0 | LC_CTYPE=C xargs -0 sed -i '' s/"name=\"Router\""/"name=\"$NEW_ROOT-config\""/g
find src/main/mule/interface.xml  -type f -print0 | LC_CTYPE=C xargs -0 sed -i '' s/"config-ref=\"Router\""/"config-ref=\"$NEW_ROOT-config\""/g
printf '%s%s%s\n' $COLOR_GREEN 'done' $COLOR_REST

echo;echo "############### ANYPOINT HOST UPDATE"
echo "* Using host: $ANYPOINT_HOST"
echo -n "* Updating host in pom and jenkinsfile files... "
sed -i '' "s/{{ANYPOINT_HOST}}/$ANYPOINT_HOST/g" pom.xml
sed -i '' "s/{{ANYPOINT_HOST}}/$ANYPOINT_HOST/g" Jenkinsfile
printf '%s%s%s\n' $COLOR_GREEN 'done' $COLOR_REST

echo;echo "############### ANYPOINT REGION UPDATE"
echo "* Using region: $REGION"
echo -n "* Updating region in jenkinsfile file... "
sed -i '' "s/{{REGION}}/$REGION/g" Jenkinsfile
printf '%s%s%s\n' $COLOR_GREEN 'done' $COLOR_REST

echo;echo "############### GROUP ID UPDATE"
if [ -z "$GROUP_ID" ]; then
    print_group_id_missing
else
    echo -n "* Updating Group Id... "
    sed -i '' "s/{{GROUP_ID}}/$GROUP_ID/g" pom.xml
    printf '%s%s%s\n' $COLOR_GREEN 'done' $COLOR_REST
fi

echo;echo "############### GROUP NAME UPDATE"
if [ -z "$GROUP_NAME" ]; then
    print_group_name_missing
else
    echo -n "* Updating Group Name... "
    sed -i '' "s/{{GROUP_NAME}}/$GROUP_NAME/g" Jenkinsfile
    printf '%s%s%s\n' $COLOR_GREEN 'done' $COLOR_REST
fi

echo;echo "############### MAVEN GLOBAL SETTINGS ID"
echo "* Using maven global settings id: $MVN_GLBL_SETT_ID"
echo -n "* Updating id in jenkinsfile file... "
sed -i '' "s/{{MVN_GLBL_SETT_ID}}/$MVN_GLBL_SETT_ID/g" Jenkinsfile
printf '%s%s%s\n' $COLOR_GREEN 'done' $COLOR_REST


echo;echo "############### GIT CONFIGURATION"
echo "* Initializing git..."
git init

if [ -z "$REPO_URL" ]; then
    print_git_repo_missing
else
    # Escaping the repo url
    REPO_ESC_URL=""
    for (( i=0; i<${#REPO_URL}; i++ )); do
        if [ "${REPO_URL:$i:1}" == '/' ]; then 
            REPO_ESC_URL="$REPO_ESC_URL\\${REPO_URL:$i:1}"
        else
            REPO_ESC_URL="$REPO_ESC_URL${REPO_URL:$i:1}"
        fi
    done
    echo -n "** Updating pom.xml... "
    sed -i '' "s/{{REPO_URL}}/$REPO_ESC_URL/g" pom.xml
    printf '%s%s%s\n' $COLOR_GREEN 'done' $COLOR_REST
    echo -n "** Updating git remote url... "
    git remote set-url origin "$REPO_URL"
    printf '%s%s%s\n' $COLOR_GREEN 'done' $COLOR_REST
fi

echo;echo "#### STEP3: CLEANING PROJECT"
echo -n "* removing files..."
rm -f "$SCRIPT_NAME"
rm -f "ci-cd_setup.md"
rm -r "assets"
printf '%s%s%s\n' $COLOR_GREEN 'done' $COLOR_REST


echo;read -p "Do you want to commit the changes on your brand new project ? (y/N) " decision
if [ "$decision" != "Y" ] && [ "$decision" != "y" ]; then
    echo;echo "* git commit skipped."
else
    echo -n "* Committing initial changes... "
    git commit -am "Project init from template"
    printf '%s%s%s\n' $COLOR_GREEN 'done' $COLOR_REST
fi

cd "../$OLD_ROOT"
echo; echo "Clone end.";
