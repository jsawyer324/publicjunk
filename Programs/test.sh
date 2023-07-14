#!/bin/sh

for D in ./*; do
    if [ -d "${D}" ]; then
        echo "${D}"
    fi
done
