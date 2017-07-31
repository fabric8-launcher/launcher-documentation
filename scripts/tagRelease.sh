#!/bin/bash

# Not tagging if HEAD is already tagged
if git name-rev --tags --name-only --no-undefined HEAD &>/dev/null; then
	read -p "Your latest commit is tagged. Do you really want to re-tag? [yN] " choice
	case $choice in
		[Yy] ) :;;
		* ) exit;;
	esac
fi

# Parsing current tag

# Using name-rev is not good because it only gives you one tag, and not
# necessary the latest version
today_tag="$(date '+%Y-%m-%d')"
latest_today_tag="$(git tag | grep "$today_tag" | sort | tail -1)"
suffix="$(echo $latest_today_tag | awk -F '_' '{print $2}')"

# We released exactly once today
if [ "$latest_today_tag" == "$today_tag" ]; then
	tag="${today_tag}_2"
# We released today at least twice
elif [ "$suffix" != "" ]; then
	tag="${today_tag}_$((suffix+1))"
# We have not released today yet
else
	tag="${today_tag}"
fi

echo Tagging with "${tag}".
echo Do not forget to push the tags: git push --tags \$REMOTE

git tag "${tag}"
