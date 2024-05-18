#!/bin/sh

zip -r -o -X -ll tunOnTether_$(cat module.prop | grep 'version=' | awk -F '=' '{print $2}').zip ./ -x '.git/*' -x 'build.sh' -x '.github/*' -x 'tot.json' -x '.git*'
