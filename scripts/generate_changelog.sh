#!/usr/bin/env bash

LOGHUB_TEMPFILE='CHANGELOG.temp'
TOKEN_FILE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../.github_token"

# Get milestone to generate
if [ $# -eq 0 ]; then
    echo 'You must select which milestone to generate. Use the milestone name, not the numerical ID. Usage:

  ./generate_changelog.sh NAME_OF_MILESTONE
' >&2
    exit 1
else
    milestone="$1"
fi

# Check if all non-standard binaries are present
if ! loghub -h &>/dev/null; then
    echo 'The loghub binary is missing. To install it, ensure you have pip installed
and execute:

  pip install --user loghub
' >&2
    exit 1
fi
if ! pandoc --version &>/dev/null; then
    echo "The pandoc binary is missing, please install it." >&2
    exit 1
fi

# Get GitHub token
read -p 'Your GitHub token (leave empty for no authentication--not recommended): ' token
if test -z $token; then
    if test -f $TOKEN_FILE; then
        echo "Loading GitHub token from file." >&2
        token_string="--token $(cat $TOKEN_FILE)"
    else
        echo "No token provided, proceeding without authentication.
Warning: Your query may be rejected by GitHub. If you get an empty result, try
specifying a GitHub token while running the script." >&2
        token_string=""
    fi
else
    token_string="--token ${token}"
fi

# Get the issues
test -f $LOGHUB_TEMPFILE && cleanup_needed=1
loghub 'openshiftio/appdev-documentation' --milestone "${milestone}" $token_string | grep 'Issue ' | pandoc -f markdown -t asciidoc | tee /tmp/foo.adoc
test -z cleanup_needed || rm $LOGHUB_TEMPFILE 2>/dev/null
