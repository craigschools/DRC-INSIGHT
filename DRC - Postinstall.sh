
#!/bin/bash

LOG="/var/log/drc-insight-configuration.log"
CONFIG="/Library/Application Support/com.datarecognitioncorp.drcinsight.mac/DRCConfiguration.json"
APP="/Applications/DRC INSIGHT.app"

OU_ID="$4"
HTTPS_PROXY="$5"

exec > >( /usr/bin/tee -a "$LOG" ) 2>&1

echo ""
echo "=========================================="
echo "DRC INSIGHT Configuration"
echo "$(date)"
echo "=========================================="

# Validate OU ID
if [[ -z "$OU_ID" ]]; then
    echo "ERROR: No OU ID supplied in JAMF Parameter 4."
    exit 1
fi

if [[ ! "$OU_ID" =~ ^[A-Za-z0-9_-]+$ ]]; then
    echo "ERROR: Invalid OU ID format: $OU_ID"
    exit 1
fi

echo "OU ID supplied: $OU_ID"

# Validate proxy parameter
if [[ "$HTTPS_PROXY" == *$'\n'* || "$HTTPS_PROXY" == *$'\r'* ]]; then
    echo "ERROR: Invalid proxy URL."
    exit 1
fi

if [[ -n "$HTTPS_PROXY" ]]; then
    echo "HTTPS proxy supplied."
else
    echo "No HTTPS proxy supplied. Proxy will be cleared."
fi

# Verify application
if [[ ! -d "$APP" ]]; then
    echo "ERROR: Application not found: $APP"
    exit 1
fi

echo "Application found: $APP"

# Verify configuration
if [[ ! -f "$CONFIG" ]]; then
    echo "ERROR: Configuration file not found: $CONFIG"
    exit 1
fi

echo "Configuration found: $CONFIG"

# Pass values to macOS JavaScript for JSON processing
export DRC_CONFIG_PATH="$CONFIG"
export DRC_OU_ID="$OU_ID"
export DRC_HTTPS_PROXY="$HTTPS_PROXY"

# Update and verify JSON
if /usr/bin/osascript -l JavaScript <<'JXA'
ObjC.import('Foundation');

var env = $.NSProcessInfo.processInfo.environment;

var path = ObjC.unwrap(env.objectForKey('DRC_CONFIG_PATH'));
var ouID = ObjC.unwrap(env.objectForKey('DRC_OU_ID'));
var proxy = ObjC.unwrap(env.objectForKey('DRC_HTTPS_PROXY'));

if (!path || !ouID) {
    throw new Error("Configuration path or OU ID is missing.");
}

// Read existing JSON
var contents = $.NSString.stringWithContentsOfFileEncodingError(
    path,
    $.NSUTF8StringEncoding,
    null
);

if (!contents) {
    throw new Error("Could not read configuration file.");
}

// Parse JSON
var config = JSON.parse(ObjC.unwrap(contents));

if (typeof config !== 'object' ||
    config === null ||
    Array.isArray(config)) {
    throw new Error("Configuration root must be a JSON object.");
}

// Update OU ID
config.ouIds = [ouID];

// Ensure config object exists
if (typeof config.config !== 'object' ||
    config.config === null ||
    Array.isArray(config.config)) {
    config.config = {};
}

// Update HTTPS proxy
config.config.httpsProxy = proxy || "";

// Serialize JSON
var output = JSON.stringify(config, null, 2) + "\n";

// Write atomically
var writeResult = $.NSString.stringWithString(output)
    .writeToFileAtomicallyEncodingError(
        path,
        true,
        $.NSUTF8StringEncoding,
        null
    );

if (!writeResult) {
    throw new Error("Failed to write configuration.");
}

// Read back for verification
var verifyContents = $.NSString.stringWithContentsOfFileEncodingError(
    path,
    $.NSUTF8StringEncoding,
    null
);

if (!verifyContents) {
    throw new Error("Could not read configuration after writing.");
}

var verifiedConfig = JSON.parse(ObjC.unwrap(verifyContents));

// Verify OU ID
if (!Array.isArray(verifiedConfig.ouIds) ||
    verifiedConfig.ouIds.length !== 1 ||
    verifiedConfig.ouIds[0] !== ouID) {
    throw new Error("OU ID verification failed.");
}

// Verify proxy
if (!verifiedConfig.config ||
    verifiedConfig.config.httpsProxy !== (proxy || "")) {
    throw new Error("HTTPS proxy verification failed.");
}

console.log("JSON successfully updated and verified.");
console.log("Verified OU ID: " + verifiedConfig.ouIds[0]);
console.log("HTTPS proxy: " + (proxy ? "Configured" : "Not configured"));
console.log("Toolkit URL preserved: " + verifiedConfig.toolkitUrl);

JXA

then
    echo "SUCCESS: DRC configuration updated and verified."
else
    echo "ERROR: JSON configuration update or verification failed."
    exit 1
fi

# Refresh Dock
echo ""
echo "Refreshing Dock..."

CONSOLE_USER=$(/usr/bin/stat -f%Su /dev/console)

if [[ -n "$CONSOLE_USER" &&
      "$CONSOLE_USER" != "root" &&
      "$CONSOLE_USER" != "loginwindow" ]]; then

    CONSOLE_UID=$(/usr/bin/id -u "$CONSOLE_USER")

    if /bin/launchctl asuser "$CONSOLE_UID" /usr/bin/killall Dock; then
        echo "SUCCESS: Dock refreshed for $CONSOLE_USER"
    else
        echo "WARNING: Could not refresh Dock."
    fi

else
    echo "No logged-in user found. Skipping Dock refresh."
fi

echo ""
echo "DRC INSIGHT deployment completed successfully."
echo "=========================================="

exit 0