#!/bin/bash

# Get branches from target repo
REPO="${1:-axelor/axelor-open-suite}"
PATTERN="${2:-^[0-9]+\.[0-9]+$}"

# Get all branches by iterating through all pages
all_branches="[]"
page=1

echo "Retrieving branches from repository $REPO..."

while true; do
  echo "  Retrieving page $page..."
  
  # Get current page
  response=$(curl -s "https://api.github.com/repos/$REPO/branches?per_page=100&page=$page")
  
  # Check if page contains branches
  branch_count=$(echo "$response" | jq '. | length')
  
  if [ "$branch_count" -eq 0 ]; then
    echo "  End of pages (page $page empty)"
    break
  fi
  
  echo "  Found $branch_count branches on page $page"
  
  # Add branches from this page to total list
  all_branches=$(echo "$all_branches" "$response" | jq -s '.[0] + .[1]')
  
  # Move to next page
  page=$((page + 1))
done

# Filter branches according to pattern and minimum version (8.0+)
branches_json=$(echo "$all_branches" | jq -c --arg pattern "$PATTERN" '
  [.[] | select(.name | test($pattern)) | .name] |
  map(select(. as $version | ($version | split(".") | .[0] | tonumber) >= 8))
')

# Check if branches were found
branch_count=$(echo "$branches_json" | jq '. | length')

if [ "$branch_count" -eq 0 ]; then
  echo "No branches found matching pattern $PATTERN (version >= 8.0)"
  echo "branches=[]" >> $GITHUB_OUTPUT
else
  echo "$branch_count branch(es) found matching pattern $PATTERN (version >= 8.0):"
  echo "$branches_json" | jq -r '.[]'
  echo "branches=$branches_json" >> $GITHUB_OUTPUT
fi 