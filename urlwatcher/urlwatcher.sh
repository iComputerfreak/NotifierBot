#!/bin/bash

cd "$(dirname "$0")"

URL_LIST_FILE="urls.list"
IMAGES_DIRECTORY="images"
# NOTE: The script variables should not contain spaces!
# We are in NotifierBot/urlwatcher
TELEGRAM_SCRIPT="$(pwd)/../tools/telegram.sh"
# Screenshot script.
#SCREENSHOT_SCRIPT="$(pwd)/../tools/screenshot.py" # When reactivating, change calls to "python3.6 "$SCREENSHOT_SCRIPT""
SCREENSHOT_SCRIPT="$(pwd)/../tools/screenshot.sh"
# Read the first line from the BOT_TOKEN file
TELEGRAM_BOT_TOKEN=$(head -n 1 ../BOT_TOKEN)
# The threshold when to consider two images matching. If two images have a normalized cross correllation >= this value, they are considered identical
NCC_THRESHOLD="0.999"
# The file where the diff image is saved to
DIFF_FILE="diff.png"
# The file where the NCC value is saved to
NCC_FILE="ncc"

# Set the PATH variable for the python script below, so it finds the geckodriver executable when executed from cron
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

echo "Starting URL Watcher..."

if [ ! -f "$URL_LIST_FILE" ]; then
    touch "$URL_LIST_FILE"
fi

if [ ! -d "$IMAGES_DIRECTORY" ]; then
    mkdir "$IMAGES_DIRECTORY"
fi

function reportChange {
    local NAME="$1"
    local IMAGE="$2"
    local NCC="$3"
    "$TELEGRAM_SCRIPT" -t "$TELEGRAM_BOT_TOKEN" -c "$CHAT_ID" \
        -i $IMAGE "$NAME has changed. NCC: $NCC"
}

function reportError {
    local NAME="$1"

    echo "Error taking screenshot. Notifying user..."
    if [ ! -f errored ]; then
        "$TELEGRAM_SCRIPT" -t "$TELEGRAM_BOT_TOKEN" -c "$CHAT_ID" \
            "Error creating a screenshot for '$NAME'"
        touch errored
    fi
}

function reportErroredResume {
    local NAME="$1"
    "$TELEGRAM_SCRIPT" -t "$TELEGRAM_BOT_TOKEN" -c "$CHAT_ID" \
            "Screenshot creation resumed for '$NAME'"
}

function reportNew {
    local NAME="$1"
    local IMAGE="$2"
    "$TELEGRAM_SCRIPT" -t "$TELEGRAM_BOT_TOKEN" -c "$CHAT_ID" -N \
        -f "$IMAGE" "Added '$NAME'"
}

function takeScreenshot {
    local URL="$1"
    local DELAY="$2"
    local ELEMENT="$3"
    "$SCREENSHOT_SCRIPT" "$URL" latest.png "$DELAY" "$ELEMENT"

    # On Error, retry once
    if [ ! -f latest.png ]; then
        echo "Error taking screenshot. Retrying..."
	    sleep 0.2
        "$SCREENSHOT_SCRIPT" "$URL" latest.png "$DELAY" "$ELEMENT"
    fi
}

function rollBack {
    # Roll back the old screenshot
    if [ -f old.png ]; then
        mv old.png latest.png
    fi
}

function rollBackAndReportError {
    # Roll back the old screenshot
    rollBack

    # NOTIFY ERROR, if not already done
    reportError "$NAME"
}

function cropScreenshot {
    local IMAGE="$1"

    # Crop the screenshot
    if [ "$WIDTH" != "0" ] && [ "$HEIGHT" != "0" ]; then
        # Neither width nor height is zero, crop the image
        convert "$IMAGE" -crop "${WIDTH}x${HEIGHT}+$X+$Y" "$IMAGE"
    fi
}

function screenshotsMatch {
    local IMAGE_OLD="$1"
    local IMAGE_LATEST="$2"

    # Calculate the normalized cross correllation between both images
    NCC=$(compare -quiet -alpha deactivate -metric NCC "$IMAGE_OLD" "$IMAGE_LATEST" "$DIFF_FILE" 2>&1)

    # Compare floats
    if [ $(echo "${NCC}<${NCC_THRESHOLD}" | bc -l) -eq 1 ]; then
        # The screenshots are not identical
        echo "Possible change detected. Confirming..."

        # Take another screenshot to confirm it's not just a one-time loading error
        # We first have to delete the changed screenshot (otherwise we cannot confirm that taking the second screenshot was a success)
        rm -f latest.png
        sleep 1
        takeScreenshot "$URL" "$DELAY" "$ELEMENT"
        # If no luck taking the second screenshot, abort
        if [ ! -f latest.png ]; then
            # Roll back the screenshot and report an error
            rollBackAndReportError

            # Skip this entry
            cd ../..
            continue
        fi

        cropScreenshot "latest.png"

        # Compare the two cropped screenshots again
        # Calculate the normalized cross correllation between both images
        NCC=$(compare -quiet -alpha deactivate -metric NCC "$IMAGE_OLD" "$IMAGE_LATEST" "$DIFF_FILE" 2>&1)

        if [ $(echo "${NCC}<${NCC_THRESHOLD}" | bc -l) -eq 1 ]; then
            # The screenshots do not match. The website has changed

            # Write detailed NCC information to a file (and don't overwrite the diff file)
            compare -verbose -alpha deactivate -metric NCC "$IMAGE_OLD" "$IMAGE_LATEST" /dev/null &> "$NCC_FILE"

            # Return false, as the screenshots do not match
            # In bash: return value 1 == error == false
            return 1
        fi
    fi

    # Write detailed NCC information to a file (and don't overwrite the diff file)
    compare -verbose -alpha deactivate -metric NCC "$IMAGE_OLD" "$IMAGE_LATEST" /dev/null &> "$NCC_FILE"

    # If statement above didn't exit, that means we have no mismatching hashes and therefore the screenshots match (return true)
    # In bash: return value 0 == true
    return 0
}

# Iterate over the lines of the urls.list
while IFS='' read -r line || [ -n "${line}" ]; do
    # Load the configuration
    NAME=$(echo $line | cut -d ',' -f1)
    X=$(echo $line | cut -d ',' -f2)
    Y=$(echo $line | cut -d ',' -f3)
    WIDTH=$(echo $line | cut -d ',' -f4)
    HEIGHT=$(echo $line | cut -d ',' -f5)
    DELAY=$(echo $line | cut -d ',' -f6)
    ELEMENT=$(echo $line | cut -d ',' -f7)
    CHAT_ID=$(echo $line | cut -d ',' -f8)
    URL=$(echo $line | cut -d ',' -f9-)

    echo "Checking $URL"
    
    # As image directory, we use the name and chat id to create unique directories

    # Create the image directory, if it does not exist yet
    if [ ! -d "$IMAGES_DIRECTORY/${NAME}.${CHAT_ID}" ]; then
        mkdir "$IMAGES_DIRECTORY/${NAME}.${CHAT_ID}"
    fi

    # Go into it
    cd "images/${NAME}.${CHAT_ID}"

    # Rename the old screenshot file, if it exists
    if [ -f latest.png ]; then
        mv latest.png old.png
    fi

    #######################
    # TAKE THE SCREENSHOT #
    #######################

    # Take the screenshot
    takeScreenshot "$URL" "$DELAY" "$ELEMENT"

    # If no luck taking the screenshot, abort
    if [ ! -f latest.png ]; then
        rollBackAndReportError

        # Skip this entry
        cd ../..
        continue
    fi

    # We now have a valid file latest.png and possibly old.png

    ##########################
    # PREPARE THE SCREENSHOT #
    ##########################

    cropScreenshot "latest.png"

    # If no old screenshot exists, there is no need to compare anything
    if [ ! -f old.png ]; then
        # Send without notification
        reportNew "$NAME" "latest.png"

        # Clear errored file if it exists (this is a new screenshot instance)
        if [ -f errored ]; then
            # Notify no error anymore
        	reportErroredResume "$NAME"
        	rm -f errored
        fi

        # No need to compare, we are done.
        cd ../..
        continue
    fi

    # We now have a valid latest.png and old.png screenshot file

    ###########################
    # COMPARE THE SCREENSHOTS #
    ###########################

    # If the new screenshot is all black or all white (some display error), ignore it
    mean=$(convert latest.png -format "%[mean]" info:)
    if [ "$mean" == "0" ] || [ "$mean" == "65535" ]; then
        rollBack
        # Skip this entry
        cd ../..
        continue
    fi

    # If there was a change
    if ! screenshotsMatch "old.png" "latest.png"; then
        # Read the NCC from the file
        NCC=$(cat "$NCC_FILE" | grep "all: " | cut -d ':' -f2 | xargs)
        reportChange "$NAME" "latest.png" "$NCC"
    fi

    # After successfully checking for changes (either no change, or change notified)
    if [ -f errored ]; then
        # Notify no error anymore
        reportErroredResume "$NAME"
        rm -f errored
    fi

    cd ../..
done < "$URL_LIST_FILE"

echo "All checks completed."
