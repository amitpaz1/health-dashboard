#!/bin/bash

# Health Dashboard Data Sync Script
# Downloads new health data from Google Drive and processes it

set -e

# Require environment variables (don't hardcode secrets!)
if [ -z "$GOG_KEYRING_PASSWORD" ] || [ -z "$GOG_ACCOUNT" ]; then
    echo "Error: GOG_KEYRING_PASSWORD and GOG_ACCOUNT must be set"
    echo "Usage: GOG_KEYRING_PASSWORD=xxx GOG_ACCOUNT=you@gmail.com ./scripts/sync.sh"
    exit 1
fi

# Change to project directory
cd "$(dirname "$0")/.."

# Create data/raw directory if it doesn't exist
mkdir -p data/raw

echo "=== Health Dashboard Sync Started ==="
echo "$(date): Starting health data sync"

# Get list of files from Google Drive
echo "Fetching file list from Google Drive..."
FILES_JSON=$(gog drive ls --parent 1d3XsiwY9EOziqJd_cpWZx9qjrNZ5QSHy --max 100 --json)

# Check if we got valid response
if [[ -z "$FILES_JSON" ]]; then
    echo "Error: Empty response from Google Drive API"
    exit 1
fi

# Use a temporary Node.js script to parse JSON and download files
cat > /tmp/parse_drive_files.js << 'EOF'
const fs = require('fs');
const { execSync } = require('child_process');

// Read JSON from stdin
let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('readable', () => {
  let chunk = process.stdin.read();
  if (chunk !== null) {
    input += chunk;
  }
});

process.stdin.on('end', () => {
  try {
    const data = JSON.parse(input);
    
    data.files.forEach(file => {
      // Only process HealthAutoExport JSON files
      if (file.name.startsWith('HealthAutoExport-') && file.name.endsWith('.json')) {
        const localPath = `data/raw/${file.name}`;
        
        // Check if file already exists
        if (!fs.existsSync(localPath)) {
          console.log(`Downloading new file: ${file.name}`);
          
          try {
            execSync(`gog drive download "${file.id}" --out "${localPath}"`, { 
              stdio: 'inherit',
              env: process.env 
            });
            
            // Verify download succeeded
            if (fs.existsSync(localPath)) {
              const stats = fs.statSync(localPath);
              const sizeKB = Math.round(stats.size / 1024);
              console.log(`✓ Downloaded: ${file.name} (${sizeKB}KB)`);
            } else {
              console.log(`✗ Failed to download: ${file.name}`);
            }
          } catch (error) {
            console.log(`✗ Error downloading ${file.name}: ${error.message}`);
          }
        } else {
          console.log(`Already have: ${file.name}`);
        }
      }
    });
  } catch (error) {
    console.error('Error parsing JSON:', error.message);
    process.exit(1);
  }
});
EOF

echo "$FILES_JSON" | node /tmp/parse_drive_files.js

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