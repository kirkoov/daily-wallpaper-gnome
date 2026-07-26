#!/usr/bin/env bash
set -euo pipefail

WALLPAPER_DIR="$HOME/Pictures/DesktopBackgrounds/"
STATE_DIR="$HOME/.local/share/daily-wallpaper"
CURRENT_FILE="$STATE_DIR/current-wallpaper.txt"
LOG_FILE="$STATE_DIR/wallpaper-history.log"
CYCLE_FILE="$STATE_DIR/cycle-number.txt"

mkdir -p "$STATE_DIR"

# Needed when run from cron under GNOME
export DISPLAY="${DISPLAY:-:0}"
DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
export DBUS_SESSION_BUS_ADDRESS

# Start cycle number if missing
if [ ! -f "$CYCLE_FILE" ]; then
	echo "1" >"$CYCLE_FILE"
fi

CYCLE="$(cat "$CYCLE_FILE")"

# Get all image files
ALL_IMAGES="$(
	find "$WALLPAPER_DIR" -type f \( \
		-iname '*.jpg' -o \
		-iname '*.jpeg' -o \
		-iname '*.png' -o \
		-iname '*.webp' \
		\) | sort
)"

if [ -z "$ALL_IMAGES" ]; then
	echo "$(date '+%F %T') | cycle=$CYCLE | NO_IMAGES | $WALLPAPER_DIR" >>"$LOG_FILE"
	exit 0
fi

# Get already-shown images for the current cycle
SHOWN_THIS_CYCLE="$(
	if [ -f "$LOG_FILE" ]; then
		grep " | cycle=$CYCLE | " "$LOG_FILE" |
			cut -d'|' -f5 |
			sed 's/^ *//;s/ *$//' || true
	fi
)"

# Pick only images not yet shown in this cycle
UNSHOWN="$(
	comm -23 \
		<(printf '%s\n' "$ALL_IMAGES") \
		<(printf '%s\n' "$SHOWN_THIS_CYCLE" | sort)
)"

# If all images have been shown, start a new cycle
if [ -z "$UNSHOWN" ]; then
	CYCLE="$((CYCLE + 1))"
	echo "$CYCLE" >"$CYCLE_FILE"

	UNSHOWN="$ALL_IMAGES"
fi

# Pick a random image from unshown list
IMAGE="$(printf '%s\n' "$UNSHOWN" | shuf -n 1)"

BASENAME="$(basename "$IMAGE")"
URI="file://$IMAGE"

# Set wallpaper for light and dark GNOME modes
gsettings set org.gnome.desktop.background picture-uri "$URI"
gsettings set org.gnome.desktop.background picture-uri-dark "$URI"

# Verify both settings were applied
CURRENT_URI="$(gsettings get org.gnome.desktop.background picture-uri | tr -d "'")"
CURRENT_URI_DARK="$(gsettings get org.gnome.desktop.background picture-uri-dark | tr -d "'")"

if [ "$CURRENT_URI" != "$URI" ] || [ "$CURRENT_URI_DARK" != "$URI" ]; then
	echo "$(date '+%F %T') | cycle=$CYCLE | FAILED | $BASENAME | $IMAGE" >>"$LOG_FILE"
	exit 1
fi

# Save current wallpaper info
{
	echo "Current wallpaper:"
	echo "$BASENAME"
	echo
	echo "Full path:"
	echo "$IMAGE"
	echo
	echo "Cycle:"
	echo "$CYCLE"
	echo
	echo "Changed at:"
	date '+%F %T'
} >"$CURRENT_FILE"

# Append to history log
echo "$(date '+%F %T') | cycle=$CYCLE | OK | $BASENAME | $IMAGE" >>"$LOG_FILE"

# Desktop notification
if command -v notify-send >/dev/null 2>&1; then
	notify-send "Wallpaper changed" "$BASENAME" || true
fi
