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
    fi
done
