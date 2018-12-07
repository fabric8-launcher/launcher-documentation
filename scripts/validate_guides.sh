#!/usr/bin/env bash

# Builds all books into DocBook 5 XML and validates them using XMLlint.

SCRIPT_SRC="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )"
XML_SCHEMA="$SCRIPT_SRC/xml-schema/docbook.xsd"

failed_builds=""
failed_validations=""
exit_status=0

echo "=== Validating Guides ==="

# Check if validation is disabled
if test -f $SCRIPT_SRC/../.validation-disabled; then
    echo Validation disabled.
    exit 0
fi

# Check for binaries
for binary in asciidoctor xmllint; do
    if ! $binary --version &>/dev/null; then
        echo The "$binary" binary is required for validation, please install it.
        exit 1
    fi
done

# Validate Books
for book in $SCRIPT_SRC/../docs/*/master.adoc; do
    dir="$(dirname $book)"
    book_name="$(basename $dir)"
    echo -e "Processing $book_name"
    pushd $dir >/dev/null

    # Check if this book is ignored in the CI builds
    if test -e .ci-ignore; then
        popd >/dev/null
        continue
    fi

    # Build title into DocBook XML and see if any errors or warnings were output
    if asciidoctor master.adoc -b docbook5 2>&1 | grep "ERROR\|WARNING"; then
        echo -e "Failed to build $book_name."
        failed_builds="$failed_builds $book_name"
        popd >/dev/null
        continue
    fi

    # Validate the DocBook XML
    if ! xmllint --schema $XML_SCHEMA master.xml 1>/dev/null; then
        echo "Failed to validate $book_name."
        failed_validations="$failed_validations $book_name"
    fi
    popd >/dev/null
done

echo

# Output failed builds
if test -n "$failed_builds"; then
    exit_status=$((exit_status+1))
    echo -e "\nFailed builds:"
    for failed_build in $failed_builds; do
        echo " * $failed_build"
    done
fi

# Output failed validations
if test -n "$failed_validations"; then
    exit_status=$((exit_status+1))
    echo -e "Failed validations:"
    for validation in $failed_validations; do
        echo " * $validation"
    done
fi

# Output result
if (($exit_status)); then
    echo -e "\nTesting failed.\n"
else
    echo -e "\nTesting passed.\n"
fi

exit $exit_status

