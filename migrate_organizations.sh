#!/bin/bash

PARENT_DIR=$1

if [[ -z "$PARENT_DIR" ]]; then
    echo "Please provide a parent directory as an argument."
    exit 1
fi

for dir in "$PARENT_DIR"/*/; do
    if [[ -d "$dir" ]]; then
        echo "Processing directory: $dir"

        node change_gitops.js "$dir"

#        CHANGED_YML_FILES=$(git ls-files --modified '*.yml')
#        if [[ -n "${CHANGED_YML_FILES}" ]]; then
#            echo "Changes detected in $dir, committing changes..."
#            APP_NAME=$(basename "$dir" | tr '[:upper:]' '[:lower:]' | tr '_' '-')
#
#            git add "$CHANGED_YML_FILES"
#            git commit -m "Revert auto-sync migration"
#            git push origin main
#        else
#            echo "No changes detected in $dir."
#        fi
    fi
done
