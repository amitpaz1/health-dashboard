#!/bin/bash

# Health Dashboard Data Sync Script
# Downloads new health data from Google Drive and processes it

set -e

# Set environment variables
export GOG_KEYRING_PASSWORD="c7382cf96ff1fc62aed89ef08b42763e"
export GOG_ACCOUNT="amit.paz@gmail.com"

# Change to project directory
cd "$(dirname "$0")/.."

# Create data/raw directory if it doesn't exist
mkdir -p data/raw

echo "=== Health Dashboard Sync Started ==="
echo "$(date): Starting health data sync"

# Get list of files from Google Drive
echo "Fetching file list from Google Drive..."
FILES_JSON=$(gog drive ls --parent 1d3XsiwY9EOziqJd_cpWZx9qjrNZ5QSHy --max 100 --json)

# Check if we got valid JSON
if ! echo "$FILES_JSON" | jq . >/dev/null 2>&1; then
    echo "Error: Invalid JSON response from Google Drive API"
    exit 1
fi

# Extract file list and download new files
echo "$FILES_JSON" | jq -r '.files[] | "\(.id) \(.name)"' | while read -r file_id filename; do
    # Only process HealthAutoExport JSON files
    if [[ "$filename" == HealthAutoExport-*.json ]]; then
        local_path="data/raw/$filename"
        
        # Check if file already exists
        if [[ ! -f "$local_path" ]]; then
            echo "Downloading new file: $filename"
            gog drive download "$file_id" --out "$local_path"
            
            # Verify download succeeded
            if [[ -f "$local_path" ]]; then
                echo "✓ Downloaded: $filename ($(du -h "$local_path" | cut -f1))"
            else
                echo "✗ Failed to download: $filename"
            fi
        else
            echo "Already have: $filename"
        fi
    fi
done

echo "Processing health data..."
if node scripts/process.js; then
    echo "✓ Data processing completed successfully"
else
    echo "✗ Data processing failed"
    exit 1
fi

# Check if we have any changes to commit
if [[ -n $(git status --porcelain) ]]; then
    echo "Committing changes..."
    git add data/raw/*.json data/dashboard.json 2>/dev/null || true
    
    # Count new files
    NEW_FILES=$(git diff --cached --name-only | grep "data/raw/" | wc -l)
    
    if [[ $NEW_FILES -gt 0 ]]; then
        COMMIT_MSG="Update health data - $NEW_FILES new files ($(date '+%Y-%m-%d %H:%M'))"
    else
        COMMIT_MSG="Update dashboard data ($(date '+%Y-%m-%d %H:%M'))"
    fi
    
    git commit -m "$COMMIT_MSG"
    
    # Push if remote exists
    if git remote get-url origin >/dev/null 2>&1; then
        echo "Pushing to remote..."
        git push origin main
        echo "✓ Changes pushed to GitHub"
    else
        echo "No remote configured - skipping push"
    fi
else
    echo "No changes to commit"
fi

echo "$(date): Health data sync completed"
echo "=== Sync Finished ==="