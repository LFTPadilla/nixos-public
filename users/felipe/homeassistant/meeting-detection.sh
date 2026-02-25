#!/usr/bin/env bash

# Meeting Detection Script
# Detects if camera or microphone is in use to determine meeting status

# Check camera usage
check_camera() {
    local camera_count=0
    
    # Check if any video devices are being used
    if command -v lsof >/dev/null 2>&1; then
        camera_count=$(lsof /dev/video* 2>/dev/null | wc -l)
    fi
    
    # Alternative method using fuser if lsof didn't work
    if [ $camera_count -eq 0 ] && command -v fuser >/dev/null 2>&1; then
        camera_count=$(fuser /dev/video* 2>/dev/null | wc -w)
    fi
    
    echo $camera_count
}

# Check microphone usage
check_microphone() {
    local mic_count=0
    
    # Check PulseAudio source outputs (active recordings)
    if command -v pactl >/dev/null 2>&1; then
        mic_count=$(pactl list source-outputs 2>/dev/null | grep -c "Source Output")
    fi
    
    echo $mic_count
}

# Get current status
camera_active=$(check_camera)
mic_active=$(check_microphone)

# Determine meeting status
if [ $camera_active -gt 0 ] || [ $mic_active -gt 0 ]; then
    meeting_status="1"
    status_text="In Meeting"
else
    meeting_status="0"
    status_text="Available"
fi

# Output for Home Assistant sensor
echo $meeting_status                                    # First line: state
echo camera_active:$camera_active                       # Attribute: camera status
echo microphone_active:$mic_active                      # Attribute: microphone status  
echo status_text:$status_text                          # Attribute: readable status
echo last_check:$(date "+%Y-%m-%d %H:%M:%S")          # Attribute: timestamp