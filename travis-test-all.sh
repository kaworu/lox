#!/usr/bin/env bash

set -e

DIR=$(dirname "$0")

export SWIFTENV_ROOT="$HOME/.swiftenv"
export PATH="$SWIFTENV_ROOT/bin:$SWIFTENV_ROOT/shims:$PATH"

# slox
(cd "${DIR}/slox" && swift test --verbose)
