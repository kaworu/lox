#!/usr/bin/env bash

set -e

DIR=$(dirname "$0")
TRAVIS_OS_NAME=$1

if [ "$TRAVIS_OS_NAME" == "linux"]; then
    export SWIFTENV_ROOT="$HOME/.swiftenv"
    export PATH="$SWIFTENV_ROOT/bin:$SWIFTENV_ROOT/shims:$PATH"
fi

# slox
(cd "${DIR}/slox" && swift test --verbose)
