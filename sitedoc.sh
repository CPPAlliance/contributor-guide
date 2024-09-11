#!/bin/bash
#
# Copyright (c) 2024 The C++ Alliance, Inc. (https://cppalliance.org)
#
# Distributed under the Boost Software License, Version 1.0. (See accompanying
# file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
#
# Official repository: https://github.com/boostorg/website-v2-docs
#


# This script is used to build the site
# documentation which is not tagged per release.
#

# Note: macos users, run these commands
# brew install findutils
# echo "export PATH=\"/opt/homebrew/opt/findutils/libexec/gnubin:\$PATH\"" >> ~/.zprofile
# . ~/.zprofile

if [ $# -eq 0 ]; then
  echo "Usage: $0 { 'develop' | 'master' }..."
  echo
  echo "Examples:"
  echo
  echo "    $0 develop        # build develop"
  echo "    $0 master         # build master"
  exit 2
fi

# Check if node and npx are available
node_version=$(node --version 2>/dev/null)
if [ -z "$node_version" ]; then
  echo "Node.js is not installed"play
  exit 1
fi
# major_version=$(echo $node_version | egrep -o "v([0-9]+)\." | cut -c 2- | rev | cut -c 2- | rev)
major_version=$(echo "$node_version" | awk -F. '{print $1}' | cut -c 2-)
echo "Node Major Version: ${major_version}"
if [ "$major_version" -lt "16" ]; then
  echo "Node.js version $node_version is not supported. Please upgrade to version 16 or higher."
  node_path=$(which node)
  echo "node_path=${node_path}"
fi
echo "Node.js version $node_version"

# Check if antora is available
PATH=$(pwd)/node_modules/.bin:$PATH
npx_version=$(npx --version 2>/dev/null)
if [ -z "$npx_version" ]; then
  echo "npx is not installed"
  exit 1
fi
echo "npx version $npx_version"

# Build UI if we have to
cwd=$(pwd)
script_dir=$(dirname "$(readlink -f "$0")")
if ! [ -e "$script_dir/antora-ui/build/ui-bundle.zip" ] || \
   find "$script_dir/antora-ui" -newer "$script_dir/antora-ui/build/ui-bundle.zip" -print -quit | grep -q .
then
  echo "Building antora-ui"
  cd "$script_dir/antora-ui" || exit
  ./build.sh
  cd "$cwd" || exit
fi

# Identify current commit id for footer
if command -v git >/dev/null && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  commit_id=$(git rev-parse HEAD)
  commit_id=$(echo ${commit_id:0:7})
else
  commit_id=""
fi
echo "Commit ID: $commit_id"

# Install node modules if needed
if [ ! -d "node_modules" ] || [ "$(find package.json -prune -printf '%T@\n' | cut -d . -f 1)" -gt "$(find node_modules -prune -printf '%T@\n' | cut -d . -f 1)" ]; then
  echo "Installing playbook node modules"
  npm ci
fi

set -x
if [ "$CI" = "true" ]; then
  ANTORA_LOG_LEVEL=all
  export ANTORA_LOG_LEVEL
fi

npx antora --fetch --attribute page-boost-branch="$1" --attribute page-commit-id="$commit_id" --stacktrace site.playbook.yml

