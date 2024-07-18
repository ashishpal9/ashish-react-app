#!/bin/bash

set -e  # Enable error handling to exit on command failures
git tag -d $(git tag -l)
git fetch --all
get_latest_tag() {
    git describe --tags --abbrev=0 || echo ""  # Return an empty string if no tags exist
}

get_latest_user_info() {
    git log --pretty=format:"%an|%ae" -n 1
}

validate_version_format() {
    local version=$1
    if ! [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Invalid version number format: $version"
        exit 1
    fi
}

increment_version() {
    local version=$1
    IFS='.' read -ra version_parts <<< "$version"
    local last_idx=$((${#version_parts[@]} - 1))
    
    # Increment the last component
    version_parts[$last_idx]=$((version_parts[$last_idx] + 1))
    
    # Carry over the increments
    for i in $(seq $last_idx -1 1); do
        if [[ "${version_parts[$i]}" -gt 9 ]]; then
            version_parts[$i]=0
            version_parts[$(($i - 1))]=$((version_parts[$(($i - 1))] + 1))
        else
            break
        fi
    done
    
    echo "${version_parts[*]}" | tr ' ' '.'
}

create_and_push_tag() {
    local tag_name=$1
    local tag_message=$2
    if ! git tag -a "$tag_name" -m "$tag_message"; then
        echo "Failed to create tag."
        exit 1
    fi
    if ! git push origin "$tag_name"; then
        echo "Failed to push the tag to the remote repository."
        exit 1
    fi
    echo "Tag created and pushed: $tag_name"
}

commit_title=$(git show --pretty=format:%s -s HEAD)
revert_key='revert'

# Get the latest tag on the current branch
latest_tag=$(get_latest_tag)

# handle git revert operation
if [[ "$commit_title" == *"$revert_key"* ]]; then
  # delete both local and remote tag that points to latest release that has issue
  git tag -d $latest_tag
  git push origin --delete $latest_tag

  # Get the latest tag after deletion
  latest_tag=$(get_latest_tag)
fi

# Get the latest user name and email from git
IFS='|' read -r user email <<< "$(get_latest_user_info)"
echo "$user"
echo "$email"

# Define the prefix for known users
case "$user" in
    "Erwin Suico")
        TAG_PREFIX="master-release-e-v"
        ;;
    "Dev Bitcot")
        TAG_PREFIX="master-release-b-v"
        ;;
    *)
        # Define the prefix for anonymous users
        TAG_PREFIX="master-release-a-v"
        ;;
esac
echo "$TAG_PREFIX"


if [ -z "$latest_tag" ]; then
    echo "No existing tags found. Starting from version 1.0.0.1"
    version="1.0.0.1"
else
    # Extract the version number from the latest tag using split a string V is the delimiter
    Extract=$(echo $latest_tag | tr "v" "\n")
    for num in $Extract
    do
    version="$num"
    done
    echo "Latest version: $version"
    validate_version_format "$version"
    # Increment the version number
    version=$(increment_version "$version")
fi
echo "New version: $version"

# Construct the new tag
new_tag="${TAG_PREFIX}${version}"
echo "New tag: $new_tag"
# Create and push the tag with message and user details
tag_message="Commit by user $user Email $email"
create_and_push_tag "$new_tag" "$tag_message"
last_commit_id=$(git rev-parse HEAD)
touch gittagversion.php
#echo "<php return ['latest_tag_name'=> '$new_tag','tag_message'=> '$tag_message','dev_name'=> '$user','dev_email'=> '$email','last_commit_id'=>'$last_commit_id',]  ?>" >  /var/www/caselink.apexpi.com/application/config/git_version_constant.php
echo "<?php defined('BASEPATH') OR exit('No direct script access allowed'); define('GIT_TAG_LATEST', '$new_tag'); define('LATEST_TAG_NAME', '$new_tag'); define('TAG_MESSAGE', '$tag_message'); define('DEV_NAME', '$user'); define('LAST_COMMIT_ID', '$last_commit_id');" > /var/www/caselink.apexpi.com/application/config/git_version_constant.php
