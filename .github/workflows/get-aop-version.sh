#!/bin/bash

# Get AOP version from settings.gradle
REPO="${1:-axelor/open-suite-webapp}"
BRANCH="${2}"

echo "Getting AOP version from $REPO branch $BRANCH..."

# Function to check if branch exists using GitHub API
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

# Function to get version mapping for cases where specific versions don't exist
get_version_mapping() {
  local version="$1"
  
  # Define version mappings: source_version -> replacement_version
  case "$version" in
    "7.0")
      echo "6.1"
      ;;
    *)
      echo "$version"  # Return original version if no mapping exists
      ;;
  esac
}

# Function to download settings.gradle with fallback
download_settings_gradle() {
  local repo="$1"
  local branch="$2"
  
  # Check if the specified branch exists
  if check_branch_or_tag_exists "$repo" "$branch"; then
    echo "Downloading settings.gradle from branch: $branch"
    curl -s "https://raw.githubusercontent.com/$repo/$branch/settings.gradle" -o settings.gradle
    
    if [ -f settings.gradle ] && [ -s settings.gradle ]; then
      echo "Successfully downloaded settings.gradle from branch: $branch"
      return 0
    else
      echo "Warning: Branch exists but settings.gradle could not be downloaded or is empty"
    fi
  fi
  
  echo "Error: Could not download settings.gradle from any available branch"
  return 1
}

# Download settings.gradle with fallback mechanism
if ! download_settings_gradle "$REPO" "$BRANCH"; then
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
    
    # Check version mapping first
    mapped_version=$(get_version_mapping "$xy_version")
    
    if [ "$mapped_version" != "$xy_version" ]; then
      echo "Version $xy_version mapped to $mapped_version"
      echo "aop_version=$mapped_version" >> $GITHUB_OUTPUT
      echo "AOP_VERSION=$mapped_version" >> $GITHUB_ENV
    else
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
fi 