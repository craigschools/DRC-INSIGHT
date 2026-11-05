# DRC INSIGHT – JAMF Deployment

Scripts, configuration, and deployment documentation for managing **DRC INSIGHT** on macOS devices using JAMF Pro.

## Overview

This deployment method uses a JAMF Pro policy to install and configure DRC INSIGHT. The policy runs two scripts (preinstall and postinstall) and is scoped using Smart Groups that leverage an Extension Attribute to track the installed application version.

The goal is to automatically install, update, and configure DRC INSIGHT while minimizing unnecessary reinstalls.

## JAMF Pro Configuration

### Policy: Install DRC INSIGHT v17.0.0

The policy should include the following:

**Packages**
- Latest DRC INSIGHT installer package.

**Scripts**

| Script | Execution Frequency |
|---|---|
| `Preinstall.sh` | Before |
| `Postinstall.sh` | After |

**Scope**

- Smart Group: `DRC INSIGHT - Old or Missing`

---

## Scripts

### 1. Preinstall.sh

**Execution:** Before

Removes existing versions of DRC INSIGHT and associated support files before installing the latest version.

The script checks for the existence of each item and skips removal if it does not exist.

**Application directories:**

- `/Applications/DRC INSIGHT`
- `/Applications/DRC INSIGHT Online Assessments`
- `/Applications/DRC INSIGHT.app`

**Support directories:**

- `/Library/Application Support/com.datarecognitioncorp.drcinsight.mac`

### 2. Postinstall.sh

**Execution:** After

Verifies the existence of the JSON configuration file created by the installer, then writes the appropriate configuration values using parameters supplied by the JAMF policy.

If no values are provided, the script skips configuration and exits.

**JAMF Script Parameters:**

| Parameter | Value | Description |
|---|---|---|
| `$4` | OU ID | DRC INSIGHT organization/unit identifier |
| `$5` | Proxy URL | Proxy server URL, if applicable |

---

## Smart Groups & Scoping

Two Smart Groups are used to determine which devices need DRC INSIGHT installed or updated.

### DRC INSIGHT - Current

Identifies devices with the correct version of DRC INSIGHT installed.

**Criteria:**

| Criteria | Operator | Value |
|---|---|---|
| Application Title | Has | DRC INSIGHT.app |
| Extension Attribute | DRC INSIGHT | Is | 17.0.0 |
| Computer Group | Member of | STUDENTS |

> Update the Extension Attribute version criteria whenever a new DRC INSIGHT release is deployed.
> Set Computer Group - Member of to whatever group you want to deploy to.

### DRC INSIGHT - Old or Missing

Identifies devices that either do not have DRC INSIGHT installed or are running an outdated version.

**Criteria:**

The Smart Group should include devices meeting either of the following conditions:

**Condition 1 – Application Missing**
- Application Title → Does Not Have → `DRC INSIGHT.app`
- AND Computer Group → Member of → `STUDENTS`

**OR**

**Condition 2 – Application Outdated**
- Computer Group → Not a Member of → `DRC INSIGHT - Current`
- AND Computer Group → Member of → `STUDENTS`
