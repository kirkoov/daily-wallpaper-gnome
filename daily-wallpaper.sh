#!/usr/bin/env bash
set -euo pipefail

WALLPAPER_DIR="$HOME/Pictures/DesktopBackgrounds/" # Change the img folder path as necessary
STATE_DIR="$HOME/.local/share/daily-wallpaper"
CURRENT_FILE="$STATE_DIR/current-wallpaper.txt"
LOG_FILE="$STATE_DIR/wallpaper-history.log"
CYCLE_FILE="$STATE_DIR/cycle-number.txt"

mkdir -p "$STATE_DIR"

# Needed when run from anacron under GNOME
export DISPLAY="${DISPLAY:-:0}"
DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
export DBUS_SESSION_BUS_ADDRESS

pick_wallpaper() {
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
			grep " | cycle=$CYCLE | OK | " "$LOG_FILE" |
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
}

apply_wallpaper() {
	gsettings set org.gnome.desktop.background picture-options 'scaled'

	gsettings set org.gnome.desktop.background picture-uri "$URI"
	gsettings set org.gnome.desktop.background picture-uri-dark "$URI"

	CURRENT_URI="$(gsettings get org.gnome.desktop.background picture-uri | sed -E "s/^(['\"])(.*)\1$/\2/")"
	CURRENT_URI_DARK="$(gsettings get org.gnome.desktop.background picture-uri-dark | sed -E "s/^(['\"])(.*)\1$/\2/")"

	if [ "$CURRENT_URI" != "$URI" ] || [ "$CURRENT_URI_DARK" != "$URI" ]; then
		echo "$(date '+%F %T') | cycle=$CYCLE | FAILED | $BASENAME | $IMAGE" >>"$LOG_FILE"
		exit 1
	fi

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

	echo "$(date '+%F %T') | cycle=$CYCLE | OK | $BASENAME | $IMAGE" >>"$LOG_FILE"

	if command -v notify-send >/dev/null 2>&1; then
		if [[ "$BASENAME" == *" -- "* ]]; then
			NOTIFY_TITLE="${BASENAME%% -- *}"
			NOTIFY_BODY="${BASENAME#* -- }"
		elif [[ "$BASENAME" == *" - "* ]]; then
			NOTIFY_TITLE="${BASENAME%% - *}"
			NOTIFY_BODY="${BASENAME#* - }"
		else
			NOTIFY_TITLE="Wallpaper changed"
			NOTIFY_BODY="$BASENAME"
		fi

		notify-send "$NOTIFY_TITLE" "$NOTIFY_BODY" || true
	fi
}

trash_image() {
	local image="$1"
	local image_dir
	local basename
	local name_max
	local trashinfo_bytes
	local max_trash_name_bytes
	local basename_bytes
	local ext
	local stem
	local short_stem
	local shortened_image

	image_dir="${image%/*}"
	basename="${image##*/}"

	name_max="$(getconf NAME_MAX "$image_dir")"
	trashinfo_bytes="$(printf '%s' '.trashinfo' | wc -c)"
	max_trash_name_bytes=$((name_max - trashinfo_bytes))
	basename_bytes="$(printf '%s' "$basename" | wc -c)"

	if [ "$basename_bytes" -le "$max_trash_name_bytes" ]; then
		gio trash "$image"
		return
	fi

	ext=".${basename##*.}"
	stem="${basename%.*}"
	short_stem="$stem"

	while [ "$(printf '%s' "${short_stem}${ext}" | wc -c)" -gt "$max_trash_name_bytes" ]; do
		short_stem="${short_stem%?}"
	done

	shortened_image="$image_dir/${short_stem}${ext}"

	if [ -e "$shortened_image" ]; then
		echo "Cannot shorten filename for trashing because the target already exists: $shortened_image" >&2
		return 1
	fi

	mv -- "$image" "$shortened_image"

	if gio trash "$shortened_image"; then
		return 0
	fi

	if ! mv -- "$shortened_image" "$image"; then
		echo "Failed to restore original filename after trashing failed: $image" >&2
	fi

	return 1
}

reject_current_wallpaper() {
	if ! command -v gio >/dev/null 2>&1; then
		echo "gio is required to reject wallpapers." >&2
		exit 1
	fi
	CURRENT_IMAGE="$(
		if [ -f "$CURRENT_FILE" ]; then
			sed -n '/^Full path:$/ {n;p;q;}' "$CURRENT_FILE"
		fi
	)"

	if [ -z "$CURRENT_IMAGE" ]; then
		echo "No current wallpaper recorded." >&2
		exit 1
	fi

	case "$CURRENT_IMAGE" in
	"$WALLPAPER_DIR"*) ;;
	*)
		echo "Refusing to trash an image outside $WALLPAPER_DIR" >&2
		exit 1
		;;
	esac

	if [ ! -f "$CURRENT_IMAGE" ]; then
		echo "Current wallpaper file does not exist: $CURRENT_IMAGE" >&2
		exit 1
	fi

	trash_image "$CURRENT_IMAGE"

	if [ -f "$LOG_FILE" ]; then
		TMP_LOG="$(mktemp "$STATE_DIR/wallpaper-history.XXXXXX")"
		awk -F ' \\| ' -v path="$CURRENT_IMAGE" '$NF != path' "$LOG_FILE" >"$TMP_LOG"
		mv "$TMP_LOG" "$LOG_FILE"
	fi

	rm -f "$CURRENT_FILE"
}

case "${1:-}" in
"") ;;

reject)
	reject_current_wallpaper
	;;
*)
	echo "Usage: $(basename "$0") [reject]" >&2
	exit 2
	;;
esac

pick_wallpaper
apply_wallpaper
