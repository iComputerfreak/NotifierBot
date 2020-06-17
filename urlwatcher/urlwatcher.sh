#!/bin/bash

cd "$(dirname "$0")"

URL_LIST_FILE="urls.list"
IMAGES_DIRECTORY="images"
# We are in NotifierBot/urlwatcher
TELEGRAM_SCRIPT="$(pwd)/../tools/telegram.sh"
# Read the first line from the BOT_TOKEN file
TELEGRAM_BOT_TOKEN=$(head -n 1 ../BOT_TOKEN)

# Set the PATH variable for the python script below, so it finds the geckodriver executable when executed from cron
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

echo "Starting URL Watcher..."

if [ ! -f "$URL_LIST_FILE" ]; then
    touch "$URL_LIST_FILE"
fi

if [ ! -d "$IMAGES_DIRECTORY" ]; then
    mkdir "$IMAGES_DIRECTORY"
fi

# Iterate over the lines of the urls.list
while IFS='' read -r line || [ -n "${line}" ]; do
    # Load the configuration
    NAME=$(echo $line | cut -d ',' -f1)
    X=$(echo $line | cut -d ',' -f2)
    Y=$(echo $line | cut -d ',' -f3)
    WIDTH=$(echo $line | cut -d ',' -f4)
    HEIGHT=$(echo $line | cut -d ',' -f5)
    CHAT_ID=$(echo $line | cut -d ',' -f6)
    URL=$(echo $line | cut -d ',' -f7-)

    echo "Checking $URL"

    if [ ! -d "images/$NAME" ]; then
        mkdir "images/$NAME"
    fi
    cd "images/$NAME"
    # Move the old file, if it exists
    if [ -f latest.png ]; then
        mv latest.png old.png
    fi

    # Take the screenshot
    python3 /home/botmaster/tools/screenshot.py latest.png "$URL"

    if [ ! -f latest.png ]; then
        echo "Error taking screenshot."
        # Roll back the old screenshot
        if [ -f old.png ]; then
            mv old.png latest.png
        fi
        # NOTIFY ERROR
        "$TELEGRAM_SCRIPT" -t "$TELEGRAM_BOT_TOKEN" -c "$CHAT_ID" \
            "Error creating a screenshot for '$NAME'"
        exit 1
    fi

    # Crop the new screenshot
    if [ "$WIDTH" != "0" ] && [ "$HEIGHT" != "0" ]; then
        # Neither width nor height is zero, crop the image
        convert latest.png -crop "${WIDTH}x${HEIGHT}+$X+$Y" latest.png
    fi

    # If no old screenshot exists, there is no need to compare anything, exit quietly
    if [ ! -f old.png ]; then
        "$TELEGRAM_SCRIPT" -t "$TELEGRAM_BOT_TOKEN" -c "$CHAT_ID" \
            -f latest.png "Added '$NAME'"
        exit 0
    fi

    # Compare the two cropped screenshots
    HASH_OLD=$(identify -quiet -format "%#" old.png)
    HASH_LATEST=$(identify -quiet -format "%#" latest.png)

    if [ "$HASH_OLD" != "$HASH_LATEST" ]; then
        # The screenshots are not identical!
        # NOTIFY
        "$TELEGRAM_SCRIPT" -t "$TELEGRAM_BOT_TOKEN" -c "$CHAT_ID" \
            -i latest.png "$NAME has changed"
    fi

    cd ../..
done < "$URL_LIST_FILE"

echo "All checks completed."
