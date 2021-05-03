#!/bin/bash
/usr/bin/google-chrome --headless --disable-gpu --window-size=1920,3000 --screenshot=$1 $2 --user-agent="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.50 Safari/537.36"
