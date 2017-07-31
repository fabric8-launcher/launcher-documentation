#!/bin/bash


failed_builds=""
failed_validations=""
exit_status=0

for dir in $(dirname docs/*/master.adoc); do
    echo -e "\nBuilding $dir"
    pushd $dir >/dev/null

    # Check if this book is ignored in the CI builds
    if test -e .ci-ignore; then
        popd >/dev/null
        continue
    fi

    # Build title into DocBook XML and see if any errors or warnings were output
    if asciidoctor master.adoc -b docbook5 2>&1 | grep "ERROR\|WARNING"; then
        echo -e "Failed to build $dir."
        failed_builds="$failed_builds $dir"
        popd >/dev/null
        continue
    fi

    # Validate the DocBook XML
    if ! xmllint --schema http://docbook.org/xml/5.0/xsd/docbook.xsd master.xml 1>/dev/null; then
        echo "Failed to validate $dir."
        failed_validations="$failed_validations $dir"
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

exit $exit_status

