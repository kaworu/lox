#!/usr/bin/env bash

set -e

DIR=$(dirname "$0")

# see .travis.yml
if [ -f ~/.swiftenv/init ]; then
    cat ~/.swiftenv/init
    . ~/.swiftenv/init
fi

# slox
(cd "${DIR}/slox" && swift test --verbose)
