#!/bin/bash

set -e

# Check parameters
if [ $# -ne 2 ]; then
    echo "Usage: $0 WEBAPP_REPO AOS_BRANCH"
    echo "Example: $0 axelor/open-suite-webapp 8.0"
    exit 1
fi

WEBAPP_REPO="${1:-axelor/open-suite-webapp}"
AOS_BRANCH="${2:-master}"

echo "Searching for branch '$AOS_BRANCH' in repo '$WEBAPP_REPO'..."

# Function to check if branch or tag exists using GitHub API
check_branch_or_tag_exists() {
  local repo="$1"
  local ref="$2"
  
  echo "Checking if branch or tag '$ref' exists in repository '$repo'..."
  
  # First, check if it's a branch
  echo "Checking branches..."
  local branch_response=$(curl -s "https://api.github.com/repos/$repo/branches/$ref")
  
  # Check if the response contains branch information (not an error)
  if echo "$branch_response" | jq -e '.name' > /dev/null 2>&1; then
    echo "Branch '$ref' exists in repository '$repo'"
    return 0
  fi
  
  # If not a branch, check if it's a tag
  echo "Branch not found, checking tags..."
  local next_url="https://api.github.com/repos/$repo/tags?per_page=100"
  local page_num=1
  
  while [ -n "$next_url" ]; do
    echo "Checking tags page $page_num..."
    local tags_response=$(curl -s "$next_url")
    
    # Check if the tag exists in current page
    if echo "$tags_response" | jq -e --arg tag "$ref" '.[] | select(.name == $tag)' > /dev/null 2>&1; then
      echo "Tag '$ref' exists in repository '$repo' (page $page_num)"
      return 0
    fi
    
    # Get next page URL from Link header
    next_url=$(curl -sI "$next_url" | grep -i '^link:' | sed -n 's/.*<\([^>]*\)>; rel="next".*/\1/p')
    page_num=$((page_num + 1))
    
    # Safety check to avoid infinite loop
    if [ $page_num -gt 20 ]; then
      echo "Warning: Stopped after 20 pages to avoid infinite loop"
      break
    fi
  done
  
  echo "Neither branch nor tag '$ref' exists in repository '$repo'"
  return 1
}

# Check if branch or tag exists in webapp repo
if check_branch_or_tag_exists "$WEBAPP_REPO" "$AOS_BRANCH"; then
    WEBAPP_BRANCH="$AOS_BRANCH"
    echo "Branch or tag '$AOS_BRANCH' found in $WEBAPP_REPO"
else
    echo "ERROR: Branch or tag '$AOS_BRANCH' not found in $WEBAPP_REPO"
    exit 1
fi

echo "Selected webapp branch: '$WEBAPP_BRANCH'"

# Export variable for GitHub Actions
echo "WEBAPP_VERSION=$WEBAPP_BRANCH" >> $GITHUB_ENV