#!/bin/bash

cd "$(dirname "$0")"

URL_LIST_FILE="urls.list"
IMAGES_DIRECTORY="images"
# NOTE: The script variables should not contain spaces!
# We are in NotifierBot/urlwatcher
TELEGRAM_SCRIPT="$(pwd)/../tools/telegram.sh"
# Screenshot script.
SCREENSHOT_SCRIPT="$(pwd)/../tools/screenshot.py"
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

    if [ ! -d "$IMAGES_DIRECTORY/$NAME" ]; then
        mkdir "$IMAGES_DIRECTORY/$NAME"
    fi
    cd "images/$NAME"
    # Move the old file, if it exists
    if [ -f latest.png ]; then
        mv latest.png old.png
    fi

    # Take the screenshot
    python3 "$SCREENSHOT_SCRIPT" latest.png "$URL"

    # On Error, retry
    if [ ! -f latest.png ]; then
        echo "Error taking screenshot. Retrying..."
        python3 "$SCREENSHOT_SCRIPT" latest.png "$URL"
    fi

    # If still no luck taking the screenshot, abort
    if [ ! -f latest.png ]; then
        echo "Error taking screenshot. Notifying user..."

        # Roll back the old screenshot
        if [ -f old.png ]; then
            mv old.png latest.png
        fi
        # NOTIFY ERROR
        "$TELEGRAM_SCRIPT" -t "$TELEGRAM_BOT_TOKEN" -c "$CHAT_ID" \
            "Error creating a screenshot for '$NAME'"
        # Skip this entry
        cd ../..
        continue
    fi

    # Crop the new screenshot
    if [ "$WIDTH" != "0" ] && [ "$HEIGHT" != "0" ]; then
        # Neither width nor height is zero, crop the image
        convert latest.png -crop "${WIDTH}x${HEIGHT}+$X+$Y" latest.png
    fi

    # If no old screenshot exists, there is no need to compare anything
    if [ ! -f old.png ]; then
        # Send without notification
        "$TELEGRAM_SCRIPT" -t "$TELEGRAM_BOT_TOKEN" -c "$CHAT_ID" -N \
            -f latest.png "Added '$NAME'"
        cd ../..
        continue
    fi

    # Compare the two cropped screenshots
    HASH_OLD=$(identify -quiet -format "%#" old.png)
    HASH_LATEST=$(identify -quiet -format "%#" latest.png)

    if [ "$HASH_OLD" != "$HASH_LATEST" ]; then
        # The screenshots are not identical!
        echo "Possible change detected. Confirming..."
        # Take another one to confirm it's not just a one-time loading error
        python3 "$SCREENSHOT_SCRIPT" latest.png "$URL"

        # On Error, retry
        if [ ! -f latest.png ]; then
            echo "Error taking screenshot. Retrying..."
            python3 "$SCREENSHOT_SCRIPT" latest.png "$URL"
        fi

        # If still no luck taking the second screenshot, abort
        if [ ! -f latest.png ]; then
            echo "Error taking screenshot. Notifying user..."

            # Roll back the old screenshot
            if [ -f old.png ]; then
                mv old.png latest.png
            fi
            # NOTIFY ERROR
            "$TELEGRAM_SCRIPT" -t "$TELEGRAM_BOT_TOKEN" -c "$CHAT_ID" \
                "Error creating a screenshot for '$NAME'"
            # Skip this entry
            cd ../..
            continue
        fi

        # Crop the new screenshot
        if [ "$WIDTH" != "0" ] && [ "$HEIGHT" != "0" ]; then
            # Neither width nor height is zero, crop the image
            convert latest.png -crop "${WIDTH}x${HEIGHT}+$X+$Y" latest.png
        fi

        # Compare the two cropped screenshots
        HASH_OLD=$(identify -quiet -format "%#" old.png)
        HASH_LATEST=$(identify -quiet -format "%#" latest.png)
        if [ "$HASH_OLD" != "$HASH_LATEST" ]; then
            # NOTIFY
            "$TELEGRAM_SCRIPT" -t "$TELEGRAM_BOT_TOKEN" -c "$CHAT_ID" \
                -i latest.png "$NAME has changed"
        fi
    fi

    cd ../..
done < "$URL_LIST_FILE"

echo "All checks completed."
killall firefox
