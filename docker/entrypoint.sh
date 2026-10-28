#!/bin/sh
set -e

HTML_DIR="/usr/share/nginx/html"

# Default fallback values
HOMESERVER="${DEFAULT_HOMESERVER:-matrix.org}"
CALENDAR="${CALENDAR_WIDGET:-calendar-widget.commet.chat}"

echo "[commet-docker] Initializing Commet Web container..."
echo "[commet-docker] Configured default homeserver: $HOMESERVER"

# Look for global_config.json in possible Flutter web asset locations
CONFIG_LOCATIONS="
$HTML_DIR/assets/assets/config/global_config.json
$HTML_DIR/assets/config/global_config.json
"

FOUND_ANY=0

for CONFIG_PATH in $CONFIG_LOCATIONS; do
    if [ -f "$CONFIG_PATH" ]; then
        FOUND_ANY=1
        echo "[commet-docker] Updating existing config: $CONFIG_PATH"
        # Use sed to update values or jq if available
        if command -v jq >/dev/null 2>&1; then
            TMP_FILE="$(mktemp)"
            jq --arg hs "$HOMESERVER" --arg cal "$CALENDAR" \
               '.default_homeserver = $hs | .calendar_widget = $cal' \
               "$CONFIG_PATH" > "$TMP_FILE" && mv "$TMP_FILE" "$CONFIG_PATH"
            chmod 644 "$CONFIG_PATH"
        else
            sed -i "s/\"default_homeserver\":\s*\"[^\"]*\"/\"default_homeserver\": \"$HOMESERVER\"/g" "$CONFIG_PATH"
            sed -i "s/\"calendar_widget\":\s*\"[^\"]*\"/\"calendar_widget\": \"$CALENDAR\"/g" "$CONFIG_PATH"
            chmod 644 "$CONFIG_PATH"
        fi
    fi
done

if [ "$FOUND_ANY" -eq 0 ]; then
    echo "[commet-docker] No existing global_config.json found, creating defaults..."
    for DIR in "$HTML_DIR/assets/assets/config" "$HTML_DIR/assets/config"; do
        mkdir -p "$DIR"
        cat <<EOF > "$DIR/global_config.json"
{
  "default_homeserver": "$HOMESERVER",
  "calendar_widget": "$CALENDAR"
}
EOF
        chmod 644 "$DIR/global_config.json"
        echo "[commet-docker] Created $DIR/global_config.json"
    done
fi

# Ensure all files and directories in nginx html root are world-readable by nginx worker
chmod -R 755 "$HTML_DIR"
find "$HTML_DIR" -type f -exec chmod 644 {} +

echo "[commet-docker] Starting Nginx..."
exec "$@"
