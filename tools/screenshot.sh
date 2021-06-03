#!/bin/bash
# Arguments: URL, File, Delay, Element

capture-website "$1" --output="$2" --overwrite --full-page --user-agent="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.50 Safari/537.36" --delay="$3" --element="$4"
