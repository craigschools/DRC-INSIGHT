
#!/bin/bash

LOG="/var/log/drc-insight-configuration.log"
CONFIG="/Library/Application Support/com.datarecognitioncorp.drcinsight.mac/DRCConfiguration.json"
APP="/Applications/DRC INSIGHT.app"

# JAMF Parameters
OU_ID="$4"
HTTPS_PROXY="$5"

# DRC INSIGHT v17 toolkit URL
TOOLKIT_URL="https://cdn-app-prod.drcedirect.com/all/eca-device-toolkit-loader-ui/"

exec > >(/usr/bin/tee -a "$LOG") 2>&1

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

# Back up original configuration
BACKUP="${CONFIG}.backup.$(/bin/date +%Y%m%d%H%M%S)"

if ! /bin/cp -p "$CONFIG" "$BACKUP"; then
    echo "ERROR: Could not back up original configuration."
    exit 1
fi

echo "Original configuration backed up: $BACKUP"

# Pass values to JavaScript for JSON processing
export DRC_CONFIG_PATH="$CONFIG"
export DRC_OU_ID="$OU_ID"
export DRC_HTTPS_PROXY="$HTTPS_PROXY"
export DRC_TOOLKIT_URL="$TOOLKIT_URL"

echo ""
echo "Updating DRC INSIGHT configuration..."

if /usr/bin/osascript -l JavaScript <<'JXA'
ObjC.import('Foundation');

var env = $.NSProcessInfo.processInfo.environment;

var path = ObjC.unwrap(env.objectForKey('DRC_CONFIG_PATH'));
var ouID = ObjC.unwrap(env.objectForKey('DRC_OU_ID'));
var proxy = ObjC.unwrap(env.objectForKey('DRC_HTTPS_PROXY'));
var toolkitURL = ObjC.unwrap(env.objectForKey('DRC_TOOLKIT_URL'));

if (!path || !ouID || !toolkitURL) {
    throw new Error("Required configuration values are missing.");
}

// Read original configuration
var contents = $.NSString.stringWithContentsOfFileEncodingError(
    path,
    $.NSUTF8StringEncoding,
    null
);

if (!contents) {
    throw new Error("Could not read original configuration.");
}

// Parse original JSON
var original = JSON.parse(ObjC.unwrap(contents));

if (typeof original !== 'object' ||
    original === null ||
    Array.isArray(original)) {
    throw new Error("Configuration root must be a JSON object.");
}

// Ensure config object exists
if (typeof original.config !== 'object' ||
    original.config === null ||
    Array.isArray(original.config)) {
    original.config = {};
}

// Explicitly configure all three settings
original.ouIds = [ouID];
original.config.httpsProxy = proxy || "";
original.toolkitUrl = toolkitURL;

// Rebuild top-level JSON in known DRC configuration order
var ordered = {};

ordered.config = original.config;
ordered.ouIds = original.ouIds;
ordered.toolkitUrl = original.toolkitUrl;

// Preserve any additional top-level properties
Object.keys(original).forEach(function(key) {
    if (!Object.prototype.hasOwnProperty.call(ordered, key)) {
        ordered[key] = original[key];
    }
});

// Serialize with four-space indentation
var output = JSON.stringify(ordered, null, 4) + "\n";

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

// Read the written file back
var verifyContents = $.NSString.stringWithContentsOfFileEncodingError(
    path,
    $.NSUTF8StringEncoding,
    null
);

if (!verifyContents) {
    throw new Error("Could not read configuration after writing.");
}

// Parse written JSON
var verified = JSON.parse(ObjC.unwrap(verifyContents));

// Verify OU ID
if (!Array.isArray(verified.ouIds) ||
    verified.ouIds.length !== 1 ||
    verified.ouIds[0] !== ouID) {
    throw new Error("OU ID verification failed.");
}

// Verify proxy
if (!verified.config ||
    verified.config.httpsProxy !== (proxy || "")) {
    throw new Error("HTTPS proxy verification failed.");
}

// Verify toolkit URL
if (verified.toolkitUrl !== toolkitURL) {
    throw new Error("Toolkit URL verification failed.");
}

// Verify property order
var keys = Object.keys(verified);

if (keys[0] !== "config" ||
    keys[1] !== "ouIds" ||
    keys[2] !== "toolkitUrl") {
    throw new Error("Configuration property order verification failed.");
}

// Verify formatting
var expectedOutput = JSON.stringify(verified, null, 4) + "\n";

if (ObjC.unwrap(verifyContents) !== expectedOutput) {
    throw new Error("Configuration formatting verification failed.");
}

console.log("JSON successfully updated and verified.");
console.log("OU ID: " + verified.ouIds[0]);
console.log("HTTPS proxy: " + (proxy ? "Configured" : "Not configured"));
console.log("Toolkit URL: " + verified.toolkitUrl);
console.log("Property order: config, ouIds, toolkitUrl");
console.log("Formatting: 4-space indentation");

JXA

then
    echo "SUCCESS: DRC configuration updated and verified."
else
    echo "ERROR: Configuration update or verification failed."
    echo "Original configuration backup: $BACKUP"
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
