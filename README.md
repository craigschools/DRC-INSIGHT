# DRC-INSIGHT
Scripts and what not pertaining to DRC INSIGHT for state testing.

A policy is created, in my case in JAMF Pro to run 2 scripts one installer, scoped to a smart group that utilizes an Extension Attribute for app version tracking.

Policy - Install DRC INSIGHT v17.0.0

Packages:
Latest DRC Insight installer package.

Scripts:
Preinstall.sh - Set to Run Before
-Removes previous and current versions of DRC INSIGHT if they exist, otherwise skipping.
  "/Applications/DRC INSIGHT"
  "/Applications/DRC INSIGHT Online Assessments"
  "/Applications/DRC INSIGHT.app"
-Removes support files if they exist, otherwise skipping.
  "/Library/Application Support/com.datarecognitioncorp.drcinsight.mac"

Postinstall.sh - Set to Run After
-Verifies the existence of the JSON configuration file created by the installer then writes the OU ID and or Proxy URL values given in Parameters provided in the policy. If no values are given it skips and exits.
$4 = OU ID
$5 = Proxy URL


Scoping:

I have 2 Smart Groups for DRC, I scope this policy to "DRC INSIGHT - Old or Missing"

DRC INSIGHT - Current
  Criteria
    - Application Title - Has - DRC INSIGHT.app
    AND - Extension Attribute - DRC INSIGHT - Is - 17.0.0 (Adjusted as new version are released, and uploaded to JAMF)
    AND - Computer Group - Member of - STUDENTS (Or whatever group(s) you want to deploy to.
    
DRC INSIGHT - Old or Missing
  Criteria
    - Application Title - Does Not Have - DRC INSIGHT.app
    AND - Computer Group - Member of - STUDENTS (Or whatever group(s) you want to deploy to.
    OR - Computer Group - Not A Member of - DRC INSIGHT - Current 
    AND - Computer Group - Member of - STUDENTS (Or whatever group(s) you want to deploy to.

New Version Release Checklist
-Update scripts based on info in DRC INSIGHT documentation
-Download new installer package
-Upload new installer package to JAMF
-Update policy to utilize the new installer package
-Modify DRC INSIGHT - Current Smart Group to latest version number
-Go to DRC INSIGHT Install policy logs and flush the log for a test machine and observe behavior
  -If all is well, flush all logs and let the policy run on all of them, check dashboard for completion.
  -If errors occur, reevaluate scripts, installers etc and repeat on a test machine until it works correctly.
	
