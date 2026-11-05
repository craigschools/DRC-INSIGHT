#!/bin/bash
##############################################################################
# A script to collect the version of DRC Insight currently installed. #
# If not installed "Not Installed" will return back #
##############################################################################

NOT_INSTALLED="Not Installed"
RESULT=""

if [ -a /Applications/DRC\ Insight.app/Contents/Info.plist ]
  then
    RESULT=$( /usr/bin/defaults read /Applications/DRC\ Insight.app/Contents/Info.plist CFBundleShortVersionString )
else
    RESULT="$NOT_INSTALLED"
fi
/bin/echo "<result>$RESULT</result>"