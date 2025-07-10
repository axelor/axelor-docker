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
FALLBACK_BRANCH="master"

echo "Searching for branch '$AOS_BRANCH' in repo '$WEBAPP_REPO'..."

# Check if branch exists in webapp repo
if curl -s --fail "https://api.github.com/repos/$WEBAPP_REPO/branches/$AOS_BRANCH" > /dev/null 2>&1; then
    WEBAPP_BRANCH="$AOS_BRANCH"
    echo "Branch '$AOS_BRANCH' found in $WEBAPP_REPO"
else
    WEBAPP_BRANCH="$FALLBACK_BRANCH"
    echo "Branch '$AOS_BRANCH' not found in $WEBAPP_REPO"
    echo "Using default branch: '$FALLBACK_BRANCH'"
fi

# Check that fallback branch exists
if [ "$WEBAPP_BRANCH" = "$FALLBACK_BRANCH" ]; then
    if ! curl -s --fail "https://api.github.com/repos/$WEBAPP_REPO/branches/$FALLBACK_BRANCH" > /dev/null 2>&1; then
        echo "ERROR: Fallback branch '$FALLBACK_BRANCH' does not exist in $WEBAPP_REPO"
        exit 1
    fi
fi

echo "Selected webapp branch: '$WEBAPP_BRANCH'"

# Export variable for GitHub Actions
echo "WEBAPP_VERSION=$WEBAPP_BRANCH" >> $GITHUB_ENV