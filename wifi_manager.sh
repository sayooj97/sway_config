#!/bin/bash

# Function to show the main menu (Wi-Fi on/off and connect option)
show_main_menu() {
    wifi_status=$(nmcli radio wifi)
    
    # Create options for Rofi menu
    if [ "$wifi_status" = "enabled" ]; then
        options="Turn Off Wi-Fi\nConnect to Wi-Fi\nExit"
    else
        options="Turn On Wi-Fi\nExit"
    fi

    # Show options in Rofi menu with custom theme
    selection=$(echo -e "$options" | rofi -dmenu -p "Wi-Fi Options" -theme-str "@import 'path/to/your/rofi/theme.rasi'")

    echo "$selection"
}

# Function to show the Wi-Fi network selection menu
show_wifi_menu() {
    # Get a list of saved (previously connected) and available networks
    saved_networks=$(nmcli connection show --active | grep wifi | awk '{print $1}')
    available_networks=$(nmcli -f SSID dev wifi | sed -n '1!p' | awk 'NF')

    # Show saved networks first in the Rofi menu, then new available networks
    networks=$(echo -e "Saved Networks:\n$saved_networks\n\nAvailable Networks:\n$available_networks\n\nBack" | rofi -dmenu -p "Select Wi-Fi" -theme-str "@import 'path/to/your/rofi/theme.rasi'")

    echo "$networks"
}

# Main script loop
while true; do
    # Show main menu
    selection=$(show_main_menu)

    # Handle selection
    if [ "$selection" = "Turn Off Wi-Fi" ]; then
        nmcli radio wifi off
        notify-send "Wi-Fi turned off"
    elif [ "$selection" = "Turn On Wi-Fi" ]; then
        nmcli radio wifi on
        notify-send "Wi-Fi turned on"
    elif [ "$selection" = "Connect to Wi-Fi" ]; then
        while true; do
            networks=$(show_wifi_menu)

            # Exit if no network is selected or "Back" is selected
            if [ "$networks" = "Back" ] || [ -z "$networks" ]; then
                break # Return to the previous menu
            fi

            # If selected network is saved, connect directly
            if echo "$saved_networks" | grep -q "^$networks$"; then
                nmcli connection up "$networks" && \
                notify-send "Connected to saved network: $networks" || \
                notify-send "Failed to connect to $networks"
            else
                # For new networks, prompt for password
                password=$(rofi -dmenu -p "Enter password for $networks" -theme-str "@import 'path/to/your/rofi/theme.rasi'")

                # Attempt to connect using the password
                if [ -n "$password" ]; then
                    nmcli dev wifi connect "$networks" password "$password" && \
                    notify-send "Connected to new network: $networks" || \
                    notify-send "Failed to connect to $networks"
                fi
            fi
        done
    elif [ "$selection" = "Exit" ] || [ -z "$selection" ]; then
        exit # Exit the script entirely
    fi
done

