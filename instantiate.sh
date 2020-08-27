#!/bin/bash

# Execute : 
#      $ ./instantiate.sh  my-api-name  git@github:user/repository.git  07ac71-97cb-46c0-ad91-105eb78e8

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
    echo "Usage: ./instantiate.sh [api-name] [api-repo-url]"
    echo
    echo "Options:"
    echo "api-name (required): the name of the project"
    echo "api-repo-url: the url to the repo"
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

# We need the script's name in order to exclude it from searches.
SCRIPT_NAME=$(basename "$0")

# This is the template name, to be replaced in file names and file
# content.
OLD_ROOT=$(basename "$PWD")
TEMPLATE_FLAG="template-api" 


if [ "$#" -lt 1 ]; then
    print_help
    echo "[Error] You must specify at least one argument: your API's name."
    exit 1
fi

# API name.
NEW_ROOT="$1"

#API Repository
if [ "$#" -gt 1 ]; then
    REPO_URL="$2"
else
    REPO_URL=""
fi

#GROUP_ID 
if [ "$#" -gt 2 ]; then
    GROUP_ID="$3"
else
    GROUP_ID=""
fi

if [ -d "../$NEW_ROOT" ]; then
    print_help
    echo "[Error] \"$NEW_ROOT\" Directory exists. Please provide another name or remove the existing."
    exit 1
fi

echo;echo "Clone begin."


echo;echo "#### STEP1: COPY PROJECT"
# Create root directory by copying this template
echo -n "* Create new folder ../$OLD_ROOT -> ../$NEW_ROOT ... "
cp -r "../$OLD_ROOT" "../$NEW_ROOT"
cd "../$NEW_ROOT"
echo "done."

echo;echo "#### STEP2: CUSTOMIZING PROJECT"
# Rename files by replacing the project name.
while IFS= read -r -d '' old_name; do
    new_name="${old_name//$TEMPLATE_FLAG/$NEW_ROOT}"
    echo -n "* Renaming $old_name -> $new_name... "
    mv "$old_name" "$new_name"
    echo "done"
done < <(find ./src -not -path "*/.git*" -type f -name "*${TEMPLATE_FLAG}*" -print0)

# Replace project name in src files
echo -n "* Replacing project name src files... "
find ./src -type f -print0 | LC_CTYPE=C xargs -0 sed -i '' s/"$OLD_ROOT"/"$NEW_ROOT"/g
find ./src -type f -print0 | LC_CTYPE=C xargs -0 sed -i '' s/"$TEMPLATE_FLAG"/"$NEW_ROOT"/g
echo "done."

# Replace project name in POM
echo -n "* Replacing project name in POM... "
find pom.xml -type f -print0 | LC_CTYPE=C xargs -0 sed -i '' s/"$OLD_ROOT"/"$NEW_ROOT"/g
find pom.xml -type f -print0 | LC_CTYPE=C xargs -0 sed -i '' s/"$TEMPLATE_FLAG"/"$NEW_ROOT"/g
echo "done."

echo;echo "#### STEP3: GIT CONF"
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
    sed -i '' "s/\[REPLACE_WITH_REPO_URL\]/$REPO_ESC_URL/g" pom.xml
    echo "done."
    echo -n "** Updating git remote url... "
    git remote set-url origin "$REPO_URL"
    echo "done."
fi

echo;echo "#### STEP4: GROUP ID UPDATE"

if [ -z "$GROUP_ID" ]; then
    print_group_id_missing
else
    echo -n "* Updating Group Id... "
    sed -i '' "s/\[REPLACE_WITH_GROUP_ID\]/$GROUP_ID/g" pom.xml
    echo "done"
fi

echo;echo "#### STEP5: CLEANING PROJECT"
echo -n "* removing files..."
rm -f "$SCRIPT_NAME"
echo "done."

echo
read -p "Do you want to commit the changes on your brand new project ? (y/N) " decision
if [ "$decision" != "Y" ] && [ "$decision" != "y" ]; then
    echo "* Commit skipped."
else
    echo -n "* Committing initial changes... "
    git commit -am "Project init from template"
    echo "done."
fi

cd "../$OLD_ROOT"
echo; echo "Clone end.";
