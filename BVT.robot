*** Settings ***
Documentation     Build Verification Test for Redfish
Resource          ${CURDIR}${/}libs${/}webui.resource
Resource          ${CURDIR}${/}libs${/}serial.resource
Resource          ${CURDIR}${/}libs${/}bvt.resource
Resource          ${CURDIR}${/}libs${/}newman.resource
Resource          ${CURDIR}${/}libs${/}syncaccess.resource
Suite Teardown    Redfish Teardown

*** Test Cases ***
IP Address Configuration
  [Tags]  serial  runner
  Open Serial Port
  Verify Serial Login Prompt
  Login Serial
  Set IP Address

Verification for Lua Processes
  [Tags]  serial  runner
  Find All Lua Processes

Verification for Filesystem Size
  [Tags]  serial  runner
  Verify Harddisk Size is >= 1.5M

Change BMC Password
  [Tags]  password
  Check BMC Password

Change Redfish Password
  [Tags]  password
  Change Redfish Password

Newman Test Collection
  [Tags]    newman
  Run Newman Tests

UPNP Scripts
  [Tags]  runner  upnp
  Run UPNP Script

Megarac SPX - WebUI KVM Page Verification
  [Tags]  kvm  web
  Browser Setup
  KVM Page

Megarac SPX - WebUI System Inventory Page Verification
  [Tags]  sysinv  web
  Check System Information Tab
  Browser Teardown

Redfish Firmware Update
  [Tags]   serial  runner
  Run Redfish Firmware Update Script
  Check Redfish Firmware Update Successful
  Check U-Boot
