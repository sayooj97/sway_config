#!/bin/bash

# Path to store the current display mode state
STATE_FILE="/tmp/display_mode_state"

# Get current output information
OUTPUTS=$(swaymsg -t get_outputs | grep -E 'HDMI|eDP')

# Assign display names (replace with actual names from your setup)
INTERNAL_DISPLAY="eDP-1"  # Laptop's built-in display
EXTERNAL_DISPLAY="HDMI-A-1"  # External monitor

# Check if HDMI is connected
if ! echo "$OUTPUTS" | grep -q "$EXTERNAL_DISPLAY"; then
    notify-send "Error" "External display not detected"
    exit 1
fi

# Read the current display mode from the state file (default is 0 - Primary only)
if [ ! -f "$STATE_FILE" ]; then
    MODE=0
else
    MODE=$(cat "$STATE_FILE")
fi

# Cycle through modes
case "$MODE" in
    0)
        # Mode 1: Extended (both displays enabled, side by side)
        swaymsg output "$INTERNAL_DISPLAY" enable pos 1920 0 res 1920x1080
        swaymsg output "$EXTERNAL_DISPLAY" enable pos 0 0 res 1920x1080
        notify-send "Display mode" "Extended mode"
        echo 1 > "$STATE_FILE"  # Update state to 1
        ;;
    1)
        # Mode 2: Secondary (External monitor only, laptop display off)
        swaymsg output "$INTERNAL_DISPLAY" disable
        swaymsg output "$EXTERNAL_DISPLAY" enable pos 0 0 res 1920x1080
        notify-send "Display mode" "Secondary display only"
        echo 2 > "$STATE_FILE"  # Update state to 2
        ;;
    2)
        # Mode 0: Primary (Laptop display only, external monitor off)
        swaymsg output "$INTERNAL_DISPLAY" enable pos 0 0 res 1920x1080
        swaymsg output "$EXTERNAL_DISPLAY" disable
        notify-send "Display mode" "Primary display only"
        echo 0 > "$STATE_FILE"  # Reset state to 0
        ;;
    *)
        # Default: Primary display only
        swaymsg output "$INTERNAL_DISPLAY" enable pos 0 0 res 1920x1080
        swaymsg output "$EXTERNAL_DISPLAY" disable
        notify-send "Display mode" "Primary display only"
        echo 0 > "$STATE_FILE"
        ;;
esac
