#! /bin/bash

#Execute : ./adapt-api-name.sh my-api-name  git@github:user/repository.git

# This script executes the following steps:
#
# 1. Rename files by replacing "template-api" by your
#    API's name.
#
# 2. In all files' content replace "template-api" by
#    your API's name.
#
# 3. Rename root directory to new API name
#
# 4. Initializes the git configuration. 
#    If you don't supply the git repo you need to 
#        1. update the pom.xml yourself with the repo url inside <developerConnection></developerConnection>
#        2. execute : git remote set-url origin <repo-url> 
#
# You call it in the root directory of the repository and pass as the
# sole argument your API's name:
#
# $ ./adapt-api-name.sh my-new-api-sys

# Do not allow undefined variables.
set -u

# We need the script's name in order to exclude it from searches.
SCRIPT_NAME=$(basename "$0")

# This is the template name, to be replaced in file names and file
# content.
OLD_ROOT=$(basename "$PWD")
TEMPLATE_FLAG="template-api" 


if [ "$#" -lt 1 ]; then
    echo "Usage: ./script.sh [api-name]  [api-repo-url]"
    echo "You must specify at least one argument: your API's name."
    exit 1
fi

# This is your API's name.
NEW_ROOT="$1"

#API Repository
REPO_URL="$2"

if [ "$NEW_ROOT" == "$OLD_ROOT" ]; then
    echo "You must specify a name different from \"$OLD_ROOT\"."
    exit 1
fi

# Create root directory
echo "* create new folder ../$OLD_ROOT -> ../$NEW_ROOT"
cp -r "../$OLD_ROOT" "../$NEW_ROOT"
cd "../$NEW_ROOT"

# Rename files by replacing the project name.
while IFS= read -r -d '' old_name; do
    new_name="${old_name//$TEMPLATE_FLAG/$NEW_ROOT}"
    echo "* renaming $old_name -> $new_name"
    mv "$old_name" "$new_name"
done < <(find ./src -not -path "*/.git*" -type f -name "*${TEMPLATE_FLAG}*" -print0)

# Replace project name in src files
find ./src -type f -print0 | LC_CTYPE=C xargs -0 sed -i '' s/"$OLD_ROOT"/"$NEW_ROOT"/g
find ./src -type f -print0 | LC_CTYPE=C xargs -0 sed -i '' s/"$TEMPLATE_FLAG"/"$NEW_ROOT"/g

# Replace project name in POM
find pom.xml -type f -print0 | LC_CTYPE=C xargs -0 sed -i '' s/"$OLD_ROOT"/"$NEW_ROOT"/g
find pom.xml -type f -print0 | LC_CTYPE=C xargs -0 sed -i '' s/"$TEMPLATE_FLAG"/"$NEW_ROOT"/g

echo "* Initializing git..."

git init

if [ -z "$REPO_URL" ]; then
    echo ""
    echo " ______________________________________________________________________________________________________"
    echo "| !! Attention you didn't provide any repository !!"
    echo "| * Please reconfigure you git remote address using: git remote set-url origin <repo-url>"
    echo "| * Make sure to update the repo url in the pom.xml inside <developerConnection></developerConnection> "
    echo "|______________________________________________________________________________________________________"
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
    echo "** Updating pom.xml "
    sed -i '' "s/\[REPLACE_WITH_REPO_URL\]/$REPO_ESC_URL/g" pom.xml
    echo "** Updating git remote url"
    git remote set-url origin "$REPO_URL"
    echo "** Committing initale changes"
    git commit -am "Project initialization from template"
fi

echo "* Cleaning..."
rm -f "$SCRIPT_NAME"
cd "../$OLD_ROOT"
