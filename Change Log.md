## Changelog

### 2026 – DRC INSIGHT v17.0.0

Updated deployment configuration to accommodate changes in the DRC INSIGHT macOS application structure and version reporting.

#### Application Location Changes

The application is now identified at:

```text
/Applications/DRC INSIGHT.app
```

Previous application locations that may exist on devices from earlier deployments include:

```text
/Applications/DRC INSIGHT
/Applications/DRC INSIGHT Online Assessments
```

#### Support File Location

The current DRC INSIGHT support directory is:

```text
/Library/Application Support/com.datarecognitioncorp.drcinsight.mac
```

The preinstall script now removes this directory along with the application directories to ensure a clean installation.

#### Info.plist Version Key Change

DRC's application version reporting has changed.

**Previous version key:**

```text
CFBundleVersion
```

**Current version key:**

```text
CFBundleShortVersionString
```

The JAMF Extension Attribute must use `CFBundleShortVersionString` when retrieving the installed application version.

**Updated version detection:**

```bash
NOT_INSTALLED="Not Installed"
RESULT=""

if [ -a /Applications/DRC\ Insight.app/Contents/Info.plist ]
  then
    RESULT=$( /usr/bin/defaults read /Applications/DRC\ Insight.app/Contents/Info.plist CFBundleShortVersionString )
else
    RESULT="$NOT_INSTALLED"
fi
/bin/echo "<result>$RESULT</result>"
```

#### JAMF Pro Changes Required

- Update the DRC INSIGHT Extension Attribute to read `CFBundleShortVersionString` instead of `CFBundleVersion`.
- Update the preinstall script to remove the current application and support directory.
- Update the postinstall script as necessary to accommodate the current configuration file location and structure.
- Verify Smart Group version criteria against the newly reported application version.

#### Deployment Impact

Existing Extension Attributes relying on `CFBundleVersion` may no longer report the expected version. This can cause Smart Group membership and deployment scoping to behave incorrectly.

**Important:** Update and test the Extension Attribute before deploying the new version broadly.
