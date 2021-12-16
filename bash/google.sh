#!/bin/bash

# google via commandline

google() {
    Q="S@"
    GOOG_URL="https://www.google.com/search?q="
    AGENT="Mozilla/4.0"
    stream=$(curl -A "$AGENT" -skLm 10 "${GOOG_URL}\"${Q//\ /+}\"" | \
    grep -oP '\/url\?q=.+?&amp' | sed 's/\/url?q=//;s/&amp//')
    echo -e "${stream//\%/\x}"
}