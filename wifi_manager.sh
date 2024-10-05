#!/bin/bash

# Check if Wi-Fi is enabled or disabled
wifi_status=$(nmcli radio wifi)

# Create options for Rofi menu
if [ "$wifi_status" = "enabled" ]; then
    options="Turn Off Wi-Fi\nConnect to Wi-Fi"
else
    options="Turn On Wi-Fi"
fi

# Show options in Rofi menu
selection=$(echo -e "$options" | rofi -dmenu -p "Wi-Fi Options")

# Handle selection
if [ "$selection" = "Turn Off Wi-Fi" ]; then
    nmcli radio wifi off
    notify-send "Wi-Fi turned off"
elif [ "$selection" = "Turn On Wi-Fi" ]; then
    nmcli radio wifi on
    notify-send "Wi-Fi turned on"
elif [ "$selection" = "Connect to Wi-Fi" ]; then
    # Get a list of saved (previously connected) and available networks
    saved_networks=$(nmcli connection show --active | grep wifi | awk '{print $1}')
    available_networks=$(nmcli -f SSID dev wifi | sed -n '1!p' | awk 'NF')

    # Show saved networks first in the Rofi menu, then new available networks
    networks=$(echo -e "Saved Networks:\n$saved_networks\n\nAvailable Networks:\n$available_networks" | rofi -dmenu -p "Select Wi-Fi")

    # Exit if no network is selected
    [ -z "$networks" ] && exit

    # If selected network is saved, connect directly
    if echo "$saved_networks" | grep -q "^$networks$"; then
        nmcli connection up "$networks" && \
        notify-send "Connected to saved network: $networks" || \
        notify-send "Failed to connect to $networks"
    else
        # For new networks, prompt for password
        password=$(rofi -dmenu -p "Enter password for $networks")

        # Attempt to connect using the password
        if [ -n "$password" ]; then
            nmcli dev wifi connect "$networks" password "$password" && \
            notify-send "Connected to new network: $networks" || \
            notify-send "Failed to connect to $networks"
        fi
    fi
fi
