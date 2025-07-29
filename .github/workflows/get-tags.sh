#!/bin/bash

# Get tags from target repo
REPO="${1:-axelor/axelor-open-suite}"
PATTERN="${2:-^v?[0-9]+\.[0-9]+\.[0-9]+$}"
DOCKER_REPO="${3:-axelor/aos-ce}"

# Get all tags by iterating through all pages
all_tags="[]"
page=1

echo "Retrieving tags from repository $REPO..."

while true; do
  echo "  Retrieving page $page..."
  
  # Get current page
  response=$(curl -s "https://api.github.com/repos/$REPO/tags?per_page=100&page=$page")
  
  # Check if page contains tags
  tag_count=$(echo "$response" | jq '. | length')
  
  if [ "$tag_count" -eq 0 ]; then
    echo "  End of pages (page $page empty)"
    break
  fi
  
  echo "  Found $tag_count tags on page $page"
  
  # Add tags from this page to total list
  all_tags=$(echo "$all_tags" "$response" | jq -s '.[0] + .[1]')
  
  # Move to next page
  page=$((page + 1))
done

# Filter tags according to pattern and minimum version (8.0.0+)
filtered_tags=$(echo "$all_tags" | jq -c --arg pattern "$PATTERN" '
  [.[] | select(.name | test($pattern)) | .name] |
  map(select(. as $version | 
    ($version | ltrimstr("v") | split(".") | .[0] | tonumber) >= 8 and
    ($version | ltrimstr("v") | split(".") | .[1] | tonumber) >= 0 and
    ($version | ltrimstr("v") | split(".") | .[2] | tonumber) >= 0
  ))
')

echo "Getting existing Docker Hub tags from $DOCKER_REPO..."

# Get all Docker Hub tags by iterating through all pages
all_docker_tags="[]"
page=1

while true; do
  echo "  Retrieving Docker Hub page $page..."
  
  # Get current page from Docker Hub API
  docker_response=$(curl -s "https://hub.docker.com/v2/repositories/$DOCKER_REPO/tags/?page_size=100&page=$page")
  
  # Check if page contains tags
  docker_tag_count=$(echo "$docker_response" | jq '.results | length')
  
  if [ "$docker_tag_count" -eq 0 ]; then
    echo "  End of Docker Hub pages (page $page empty)"
    break
  fi
  
  echo "  Found $docker_tag_count Docker Hub tags on page $page"
  
  # Extract tag names and add to total list
  page_tags=$(echo "$docker_response" | jq '[.results[].name]')
  all_docker_tags=$(echo "$all_docker_tags" "$page_tags" | jq -s '.[0] + .[1]')
  
  # Check if there's a next page
  next_page=$(echo "$docker_response" | jq -r '.next')
  if [ "$next_page" = "null" ]; then
    echo "  No more Docker Hub pages"
    break
  fi
  
  # Move to next page
  page=$((page + 1))
done

echo "Filtering tags that don't exist on Docker Hub..."

# Filter out tags that already exist on Docker Hub
tags_json=$(echo "$filtered_tags" | jq -c --argjson docker_tags "$all_docker_tags" '
  map(select(. as $tag | $docker_tags | index($tag) | not))
')

# Check if tags were found
tag_count=$(echo "$tags_json" | jq '. | length')

if [ "$tag_count" -eq 0 ]; then
  echo "No new tags found matching pattern $PATTERN (version >= 8.0.0) that don't exist on Docker Hub"
  echo "tags=[]" >> $GITHUB_OUTPUT
else
  echo "$tag_count new tag(s) found matching pattern $PATTERN (version >= 8.0.0) that don't exist on Docker Hub:"
  echo "$tags_json" | jq -r '.[]'
  echo "tags=$tags_json" >> $GITHUB_OUTPUT
fi 