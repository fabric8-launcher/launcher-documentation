#!/usr/bin/env bash

for guide in html/docs/*.html; do
    for link in $(grep -o 'href="#[^"]*"' $guide | sed -e 's/href="#//' -e 's/"//g'); do
        if ! grep -q "<\(h[0-9]\|div\) .*id=\"$link\"" $guide; then
            echo 'The' $link 'in' $(basename $guide) 'is dead'
        fi
    done
done
