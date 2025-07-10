#!/bin/bash

# Get AOP version from settings.gradle
REPO="${1:-axelor/open-suite-webapp}"
BRANCH="${2}"
FALLBACK_BRANCH="${3:-master}"

echo "Getting AOP version from $REPO branch $BRANCH..."

# Function to check if branch exists using GitHub API
check_branch_exists() {
  local repo="$1"
  local branch="$2"
  
  echo "Checking if branch '$branch' exists in repository '$repo'..."
  
  # Use GitHub API to check if branch exists
  local api_response=$(curl -s "https://api.github.com/repos/$repo/branches/$branch")
  
  # Check if the response contains branch information (not an error)
  if echo "$api_response" | jq -e '.name' > /dev/null 2>&1; then
    echo "Branch '$branch' exists in repository '$repo'"
    return 0
  else
    echo "Branch '$branch' does not exist in repository '$repo'"
    return 1
  fi
}

# Function to download settings.gradle with fallback
download_settings_gradle() {
  local repo="$1"
  local branch="$2"
  local fallback_branch="$3"
  
  # Check if the specified branch exists
  if check_branch_exists "$repo" "$branch"; then
    echo "Downloading settings.gradle from branch: $branch"
    curl -s "https://raw.githubusercontent.com/$repo/$branch/settings.gradle" -o settings.gradle
    
    if [ -f settings.gradle ] && [ -s settings.gradle ]; then
      echo "Successfully downloaded settings.gradle from branch: $branch"
      return 0
    else
      echo "Warning: Branch exists but settings.gradle could not be downloaded or is empty"
    fi
  fi
  
  # If first attempt failed, try fallback branch
  echo "Trying fallback branch: $fallback_branch"
  if check_branch_exists "$repo" "$fallback_branch"; then
    echo "Downloading settings.gradle from fallback branch: $fallback_branch"
    curl -s "https://raw.githubusercontent.com/$repo/$fallback_branch/settings.gradle" -o settings.gradle
    
    if [ -f settings.gradle ] && [ -s settings.gradle ]; then
      echo "Successfully downloaded settings.gradle from fallback branch: $fallback_branch"
      return 0
    else
      echo "Warning: Fallback branch exists but settings.gradle could not be downloaded or is empty"
    fi
  fi
  
  # If fallback also failed, try master as last resort
  if [ "$fallback_branch" != "master" ]; then
    echo "Trying master branch as last resort"
    if check_branch_exists "$repo" "master"; then
      echo "Downloading settings.gradle from master branch"
      curl -s "https://raw.githubusercontent.com/$repo/master/settings.gradle" -o settings.gradle
      
      if [ -f settings.gradle ] && [ -s settings.gradle ]; then
        echo "Successfully downloaded settings.gradle from master branch"
        return 0
      else
        echo "Warning: Master branch exists but settings.gradle could not be downloaded or is empty"
      fi
    fi
  fi
  
  echo "Error: Could not download settings.gradle from any available branch"
  return 1
}

# Download settings.gradle with fallback mechanism
if ! download_settings_gradle "$REPO" "$BRANCH" "$FALLBACK_BRANCH"; then
  exit 1
fi

# Extract version from the line containing 'id 'com.axelor.app' version'
version_line=$(grep "id 'com.axelor.app' version" settings.gradle || echo "")

if [ -z "$version_line" ]; then
  echo "Warning: Could not find AOP version line in settings.gradle"
  echo "aop_version=latest" >> $GITHUB_OUTPUT
  echo "AOP_VERSION=latest" >> $GITHUB_ENV
else
  # Extract version number (X.Y.Z format)
  full_version=$(echo "$version_line" | sed -n "s/.*version '\([^']*\)'.*/\1/p")
  
  if [ -z "$full_version" ]; then
    echo "Warning: Could not extract version from line: $version_line"
    echo "aop_version=latest" >> $GITHUB_OUTPUT
    echo "AOP_VERSION=latest" >> $GITHUB_ENV
  else
    echo "Found full AOP version: $full_version"
    
    # Extract X.Y part (major.minor)
    xy_version=$(echo "$full_version" | sed 's/\([0-9]*\.[0-9]*\).*/\1/')
    
    echo "Extracted X.Y version: $xy_version"
    
    # Check if tag exists on Docker Hub
    echo "Checking if tag $xy_version exists on Docker Hub..."
    
    # Function to check if tag exists with pagination
    check_tag_exists() {
      local tag_to_find="$1"
      local next_url="https://hub.docker.com/v2/repositories/axelor/app-builder/tags/?page_size=100"
      local page_num=1
      
      while [ -n "$next_url" ]; do
        echo "Checking page $page_num..."
        docker_response=$(curl -s "$next_url")
        
        # Check if tag exists in current page
        if echo "$docker_response" | jq -e --arg tag "$tag_to_find" '.results[] | select(.name == $tag)' > /dev/null 2>&1; then
          echo "Tag $tag_to_find found on Docker Hub (page $page_num)"
          return 0
        fi
        
        # Get next page URL
        next_url=$(echo "$docker_response" | jq -r '.next // empty')
        page_num=$((page_num + 1))
        
        # Safety check to avoid infinite loop
        if [ $page_num -gt 10 ]; then
          echo "Warning: Stopped after 10 pages to avoid infinite loop"
          break
        fi
      done
      
      echo "Tag $tag_to_find not found on Docker Hub after checking all pages"
      return 1
    }
    
    if check_tag_exists "$xy_version"; then
      echo "aop_version=$xy_version" >> $GITHUB_OUTPUT
      echo "AOP_VERSION=$xy_version" >> $GITHUB_ENV
    else
      echo "Using latest version"
      echo "aop_version=latest" >> $GITHUB_OUTPUT
      echo "AOP_VERSION=latest" >> $GITHUB_ENV
    fi
  fi
fi 