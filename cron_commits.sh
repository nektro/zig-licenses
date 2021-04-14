#!/usr/bin/env bash

set -e

most_recent=''

while true
do
    commits=$(curl -s https://api.github.com/repos/$1/commits)
    sha=$(echo "$commits" | jq -r '.[0].sha')

    if [ -z "$most_recent" ]
    then
        most_recent="$sha"
        echo "first run of loop, commit is $sha"
        continue
    fi

    if [ "$most_recent" == "$sha" ]
    then
        echo "most recent commit is the same, sleeping"
        # sec - min - hr
        sleep $((1 * 60 * 60 * $2))
        continue
    fi

    echo "found new commit $sha"
    ./generate.sh
done
