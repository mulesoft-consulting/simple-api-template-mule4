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
OLD_ROOT='template-api'

if [ "$#" -ne 1 ]; then
    echo "You must specify exactly one argument: your API's name."
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

cp -r "../$OLD_ROOT" "../$NEW_ROOT"
cd "../$NEW_ROOT"

# Rename files by replacing the project name.
while IFS= read -r -d '' old_name; do
    new_name="${old_name//$OLD_ROOT/$NEW_ROOT}"
    echo "renaming $old_name -> $new_name"
    mv "$old_name" "$new_name"
done < <(find ./src -not -path "*/.git*" -type f -name "*${OLD_ROOT}*" -print0)

# Replace project name in src files
find ./src -type f -print0 | LC_CTYPE=C xargs -0 sed -i '' s/"$OLD_ROOT"/"$NEW_ROOT"/g

# Replace project name in POM
find pom.xml -type f -print0 | LC_CTYPE=C xargs -0 sed -i '' s/"$OLD_ROOT"/"$NEW_ROOT"/g

# Rename root directory
echo "renaming ../$OLD_ROOT -> ../$NEW_ROOT"

echo "Initializing git"

git init

if [ -z "$REPO_URL" ]; then
    echo "\tUpdatig pom.xml "
    find pom.xml -type f -print0 | LC_CTYPE=C xargs -0 sed -i '' s/'[REPLACE_WITH_REPO_URL]'/"$REPO_URL"/g
    echo "\tUpdating git remote url"
    git remote set-url origin "$REPO_URL"
else
    echo " ______________________________________________________________________________________________________"
    echo "| !! Attention you didn't provide any repository !!"
    echo "| * Please reconfigure you git remote address using: git remote set-url origin <repo-url>"
    echo "| * Make sure to update the repo url in the pom.xml inside <developerConnection></developerConnection> "
    echo "|______________________________________________________________________________________________________"
fi

cd "../$OLD_ROOT"
