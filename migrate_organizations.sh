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

        if [[ $(git status --porcelain) ]]; then
            echo "Changes detected in $dir, committing changes..."
            APP_NAME=$(basename "$dir")

            git add .
            git commit -m "Migrate $APP_NAME to work with auto-sync"
            git push origin main

            echo "Refreshing and syncing ArgoCD application: $APP_NAME"
            argocd app refresh "$APP_NAME" --hard-refresh

            argocd app sync "$APP_NAME" --wait
            if [[ $? -eq 0 ]]; then
                echo "Application '$APP_NAME' synced successfully."
            else
                echo "Failed to sync application '$APP_NAME'."
            fi
        else
            echo "No changes detected in $dir."
        fi
    fi
done