#!/usr/bin/env bash

HEADING_REGEX='^[=#] [A-Z{].*'


function get_anchor_id {
    # Parameters: file_name, heading
    file_name="$1"
    heading="$2"

    heading_lineno=$(grep -n "$HEADING_REGEX" $file | cut -f1 -d:)
    anchor_lineno=$(grep -n "^\[\(\[\|#\|id\)" $file | cut -f1 -d: | sort -n | head -1)

    echo "  Heading line: $heading_lineno" 1>&2
    echo "  Anchor line: $anchor_lineno" 1>&2

    if echo $anchor_lineno | grep -q . && [ $anchor_lineno -lt $heading_lineno ]; then
        # Anchor ID must exist and appear before the heading
        echo $(sed "$anchor_lineno!d" $file | sed -e "s%^\[\(\[\|#\|id=['\"]\)%%" | sed -e "s|[]']\?\]\W*$||")
        return $anchor_lineno
    else
        # Construct anchor ID according to Asciidoctor's default values
        echo $(echo "_${heading}" | tr [:upper:] [:lower:] | sed -e 's|[^a-z0-9]|_|g' | sed -e 's|_\+|_|g')
        return 0
    fi
}

function replace_anchor_id {
    line_number="$1"
    anchor_id="$2"
    file="$3"

    if [ $line_number -ne 0 ]; then
        sed -i "${line_number}s|.*|[id='${anchor_id}']|" $file
    else
        sed -i "1i [id='${anchor_id}']" $file
    fi
}


# Main

if [ $# -lt 2 ]; then
    echo 'Usage: ./convert.sh FILENAME_PREFIX FILE1 [FILE2] [FILE3] [...]'
    exit 1
fi

file_prefix="$1"
shift

for file in $@; do
    echo === Processing $file ===

    heading=$(grep "$HEADING_REGEX" $file | head -1 | sed -e 's|^[=# ]*||')
    name_base=$(echo $heading | tr [:upper:] [:lower:] | sed -e 's|[^a-z0-9]|-|g' | sed -e 's|-\+|-|g' -e s'|-$||' -e s'|^-\+||' -e 's/name-mission-//' -e 's/parameter-\(mission\|runtime\)-name-//')
    anchor_id="${name_base}_{context}"
    file_name="${file_prefix}${name_base}.adoc"

    echo "  Heading: $heading" 1>&2
    echo "  New anchor ID: $anchor_id" 1>&2
    echo "  New file name: $file_name" 1>&2

    # Find original anchor ID, if any
    original_anchor_id=$(get_anchor_id "$file" "$heading")
    anchor_id_line=$?
    echo "  Original anchor id: $original_anchor_id" 1>&2

    # Replace the anchor ID with a new one
    echo "  == Replacing anchor ID with a new one =="
    replace_anchor_id $anchor_id_line $anchor_id $file

    # Replace all references to the original anchor ID with the new one
    echo "  == Replacing references to old anchor ID with a new one =="
    find -name \*.adoc -exec sed -i "s|xref:${original_anchor_id}\[|xref:${anchor_id}[|g" '{}' ';'
    find -name \*.adoc -exec sed -i "s|<<${original_anchor_id}\([,>]\)|<<${anchor_id}\1|g" '{}' ';'

    # Rename the file
    echo "  == Renaming file =="
    git mv $file $(dirname $file)/$file_name 2>&1 | grep 'exists' && echo "$file_name $file" >> duplicates.list

    # Replace all include statements to the file
    echo "  == Replacing include statements =="
    find -name \*.adoc -exec sed -i "s|include::\(.\+/\)\?$(basename $file)\[|include::\1${file_name}[|" '{}' ';'
done
