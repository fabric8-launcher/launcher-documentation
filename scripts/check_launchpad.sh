#!/usr/bin/env bash

# Check if files used by fabric8-launcher/launcher-frontend were deleted. Returns 2
# on a tooling issue, returns 1 if deleted files were detected.
#
# Works by either analyzing the Git diff or by checking the files on the
# filesystem, depending on Git being available. You can provide this
# information by setting the GIT_AVAILABLE variable when running the script.
#
# NOTE: In the container docs build on ci.centos.org, Git is NOT available.

LAUNCHPAD_INDEX="https://raw.githubusercontent.com/fabric8-launcher/launcher-frontend/master/src/assets/adoc.index"
DOC_REPO_PREFIX="https://raw.githubusercontent.com/.*/launcher-documentation/master/"

echo "=== Verifying Launchpad Files ==="

# Failing gracefully if some of the used binaries is not installed
for binary in curl sed grep; do
    if ! $binary --version &>/dev/null; then
      if ! which $binary &>/dev/null; then #macOS workaround
        echo -e "The '${binary}' binary is missing. Please install it."
        exit 2
      fi
    fi
done

# Failing gracefully if the launchpad file can not be reached
if ! index_contents="$(curl -f $LAUNCHPAD_INDEX 2>/dev/null)"; then
    echo -e "Could not reach index file to test. You are probably offline."
    exit 2
fi

index_files=$(printf \\"$index_contents\\" \
    | sed -e 's|^.*"\([^"]*\)".*$|\1|' -e "s|$DOC_REPO_PREFIX||" -e '/^\W*$/d' )

# Check for deleted files if in Git environment
deleted_launchpad_files=""
if ! test -z $GIT_AVAILABLE; then
    for file in $(git diff --cached --name-only --diff-filter=D $against); do
        if printf "${index_files}" | grep -q "${file}"; then
            deleted_launchpad_files="${deleted_launchpad_files}\n  $file"
        fi
    done
# Check if files exist in non-Git environment
else
    for file in $(printf "$index_files"); do
        if ! test -f $file; then
            deleted_launchpad_files="${deleted_launchpad_files}\n  $file"
        fi
    done
fi

# Fail if any critical files were deleted
if ! test -z "$deleted_launchpad_files"; then
    echo "The following file(s) were deleted, which are required by the Launchpad app:"
    printf "$deleted_launchpad_files"
    echo -e '\n'
    test -z $GIT_AVAILABLE || echo -e "These files are required and must not be deleted. If you want to commit anyway,\nrun the 'git commit' command with the '--no-verify' option."
    exit 1
else
    echo "Success."
    exit 0
fi

