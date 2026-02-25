#!/bin/bash
set -euo pipefail

# Home Assistant sensor script for time information
# Outputs current time in multiple formats for sensor attributes

date "+%H:%M"                    # First line: sensor state (HH:MM format)
echo "formatted:$(date --iso-8601=seconds)" # ISO 8601 formatted date and time
echo "unix:$(date "+%s")"         # Unix timestamp
