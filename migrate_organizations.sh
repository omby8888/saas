#!/bin/bash

PARENT_DIR=$1
ARGO_TOKEN=$2
ARGO_URL=${3:-http://localhost:8080}

if [[ -z "$PARENT_DIR" ]]; then
    echo "Please provide a parent directory as an argument."
    exit 1
fi

for dir in "$PARENT_DIR"/*/; do
    if [[ -d "$dir" ]]; then
        echo "Processing directory: $dir"

        node change_gitops.js "$dir"

        CHANGED_YML_FILES=$(git ls-files --modified '*.yml')
        if [[ -n "${CHANGED_YML_FILES}" ]]; then
            echo "Changes detected in $dir, committing changes..."
            APP_NAME=$(basename "$dir" | tr '[:upper:]' '[:lower:]' | tr '_' '-')

            git add "$CHANGED_YML_FILES"
            git commit -m "Migrate $APP_NAME to work with auto-sync"
            git push origin main

            echo "Refreshing and syncing ArgoCD org application: $APP_NAME"
            curl -X GET "${ARGO_URL}/api/v1/applications/${APP_NAME}?refresh=hard&appNamespace=default&project=ocean" \
                -H "Authorization: Bearer ${ARGO_TOKEN}" \
                -H "Content-Type: application/json"

            curl -X POST "${ARGO_URL}/api/v1/applications/${APP_NAME}/sync" \
                -H "Authorization: Bearer ${ARGO_TOKEN}" \
                -H "Content-Type: application/json" \
                -d "{\"project\": \"ocean\", \"appNamespace\": \"default\", \"prune\": true, \"retryStrategy\": {\"limit\": 0}}"
        else
            echo "No changes detected in $dir."
        fi
    fi
done
