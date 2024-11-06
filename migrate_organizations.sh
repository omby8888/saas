#!/bin/bash

PARENT_DIR=$1

if [[ -z "$PARENT_DIR" ]]; then
    echo "Please provide a parent directory as an argument."
    exit 1
fi

# Iterate over each directory in the parent directory
for dir in "$PARENT_DIR"/*/; do
    if [[ -d "$dir" ]]; then
        echo "Processing directory: $dir"

        # Run the Node.js script on the directory
        node change_gitops.js "$dir"

        # Check for changes in Git
        cd "$dir"
        if [[ $(git status --porcelain) ]]; then
            echo "Changes detected in $dir, committing changes..."

            # Stage all changes, commit, and push
            git add .
            git commit -m "Auto-update manifests in $(basename "$dir")"
            git push origin main  # Adjust branch as needed

            # Use ArgoCD CLI to refresh and sync the application
            APP_NAME=$(basename "$dir")
            echo "Refreshing and syncing ArgoCD application: $APP_NAME"

            # Refresh the application
            argocd app get "$APP_NAME" &>/dev/null
            if [[ $? -ne 0 ]]; then
                echo "ArgoCD application '$APP_NAME' not found, skipping..."
                continue
            fi

            # Perform hard refresh
            argocd app refresh "$APP_NAME" --hard-refresh

            # Sync the application and wait for sync completion
            argocd app sync "$APP_NAME" --wait
            if [[ $? -eq 0 ]]; then
                echo "Application '$APP_NAME' synced successfully."
            else
                echo "Failed to sync application '$APP_NAME'. Check ArgoCD logs for details."
            fi
        else
            echo "No changes detected in $dir."
        fi

        # Go back to the parent directory to process the next folder
        cd "$PARENT_DIR"
    fi
done