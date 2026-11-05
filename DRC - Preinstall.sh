
#!/bin/bash

LOG="/var/log/drc-insight-preinstall.log"

exec > >( /usr/bin/tee -a "$LOG" ) 2>&1

echo ""
echo "=========================================="
echo "DRC INSIGHT Preinstall Cleanup"
echo "$(date)"
echo "=========================================="

# Previous and current application locations
OLD_PATHS=(
    "/Applications/DRC INSIGHT"
    "/Applications/DRC INSIGHT Online Assessments"
    "/Applications/DRC INSIGHT.app"
)

# DRC INSIGHT support and configuration directory
SUPPORT_PATHS=(
    "/Library/Application Support/com.datarecognitioncorp.drcinsight.mac"
)

# Stop DRC INSIGHT if running
echo "Checking for running DRC INSIGHT processes..."

if /usr/bin/pgrep -x "DRC_INSIGHT" >/dev/null 2>&1; then
    echo "Stopping DRC INSIGHT..."
    /usr/bin/pkill -x "DRC_INSIGHT" 2>/dev/null || true
    /bin/sleep 2
fi

# Remove application installations
echo ""
echo "Removing previous application installations..."

for OLD_PATH in "${OLD_PATHS[@]}"; do

    if [[ -d "$OLD_PATH" ]]; then
        echo "Removing: $OLD_PATH"

        if /bin/rm -rf "$OLD_PATH"; then
            echo "Successfully removed: $OLD_PATH"
        else
            echo "ERROR: Could not remove: $OLD_PATH"
            exit 1
        fi
    else
        echo "Not present, skipping: $OLD_PATH"
    fi

done

# Remove support and configuration directories
echo ""
echo "Removing DRC INSIGHT support files..."

for SUPPORT_PATH in "${SUPPORT_PATHS[@]}"; do

    if [[ -d "$SUPPORT_PATH" ]]; then
        echo "Removing: $SUPPORT_PATH"

        if /bin/rm -rf "$SUPPORT_PATH"; then
            echo "Successfully removed: $SUPPORT_PATH"
        else
            echo "ERROR: Could not remove: $SUPPORT_PATH"
            exit 1
        fi
    else
        echo "Not present, skipping: $SUPPORT_PATH"
    fi

done

echo ""
echo "DRC INSIGHT cleanup completed successfully."
echo "=========================================="

exit 0