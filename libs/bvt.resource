*** Settings ***
Documentation   This library will be used to get fw, image signing tool and yafu flash from the users runner OR from ftp
Resource        ${CURDIR}/webui.resource
Resource        ${CURDIR}/serial.resource
Library         Process
Library         String
Library         OperatingSystem
Library         Selenium2Library
Library         Collections
Library         DateTime

*** Variables ***
${USER}              admin
${DEFAULT_PASSWORD}  admin
${PASSWORD}          admin123
${INTERFACE_NAME}    eno1
${BMC_IP}            172.31.1.106
${NEWMAN_TESTS}      //h1[@class="display-1"]
${IMAGE_FILE}        encrypted_wilsoncity.ima_enc
${START}             ${EMPTY}
${STOP}              ${EMPTY}

*** Keywords ***
Redfish Teardown
  [Documentation]  Suite Teardown for Serial Port and Browser
  ${status} =  Run Keyword and Return Status  Port Should Be Open
  Run Keyword If  '${status}'=='True'  Close All Ports
  ${status} =  Run Keyword and Return Status  Get Window Indetifiers
  Run Keyword If  '${status}'=='True'  Browser Teardown

Check BMC Password
  [Documentation]  Runs IPMI command to check password for MegaRac Spx
  ${result} =      Run Process  ipmitool    -U  ${USER}     -P  ${PASSWORD}    -I  lanplus     -H  ${BMC_IP}   raw  6  1
  Log              ${result.stderr}
  Run Keyword If    '${result.stderr}'=='Error: Unable to establish IPMI v2 / RMCP+ session'  Change BMC Password
  ...  ELSE         Pass Execution  Password Already Changed!

Change BMC Password
  [Documentation]  Runs IPMI command to change password for MegaRac Spx
  FOR    ${INDEX}    IN RANGE    1   20
  ${result_password_set} =     Run Process  ipmitool    -U  ${USER}     -P  ${DEFAULT_PASSWORD}    -I  lanplus     -H  ${BMC_IP}   user    set     password    2   ${PASSWORD}
  Log  ${result_password_set.stderr}
  Exit For Loop If    '${result_password_set.stderr}'!='Error: Unable to establish IPMI v2 / RMCP+ session'
  END
  Sleep  5s
  ${result} =      Run Process  ipmitool    -U  ${USER}     -P  ${PASSWORD}    -I  lanplus     -H  ${BMC_IP}   raw  6  1
  Log  ${result.stderr}
  Run Keyword If    '${result.stderr}'=='Error: Unable to establish IPMI v2 / RMCP+ session'   Fail    BMC Password Change not yet successful!

Chassis Power Off
  [Documentation]  Runs IPMI command to power off
  FOR    ${INDEX}    IN RANGE    1   20
  ${result_off} =      Run Process    ipmitool    -U  ${USER}     -P  ${PASSWORD}     -I  lanplus     -H  ${BMC_IP}    chassis     power     off
  Sleep  5s
  Log  ${result_off.stdout}
  ${result_status} =      Run Process    ipmitool    -U  ${USER}     -P  ${PASSWORD}     -I  lanplus     -H  ${BMC_IP}    chassis     power     status
  Log  ${result_status.stdout}
  Exit For Loop If   '${result_status.stdout}'=='Chassis Power is off'
  Sleep   1s
  END

Chassis Power On
  [Documentation]  Runs IPMI command to power on
  FOR    ${INDEX}    IN RANGE    1   20
  ${result_on} =      Run Process    ipmitool    -U  ${USER}     -P  ${PASSWORD}     -I  lanplus     -H  ${BMC_IP}    chassis     power     on
  Sleep  5s
  Log  ${result_on.stdout}
  ${result_status} =      Run Process    ipmitool    -U  ${USER}     -P  ${PASSWORD}     -I  lanplus     -H  ${BMC_IP}    chassis     power     status
  Log  ${result_status.stdout}
  Exit For Loop If   '${result_status.stdout}'=='Chassis Power is on'
  Sleep   1s
  END

Power Cycle BMC
  [Documentation]  Runs IMPI command to power cycle BMC
  FOR    ${INDEX}    IN RANGE    1   20
  ${result} =      Run Process    ipmitool    -U  ${USER}     -P  ${PASSWORD}     -I  lanplus     -H  ${BMC_IP}    raw   6    2
  Exit For Loop If    '${result.stderr}'!='Error: Unable to establish IPMI v2 / RMCP+ session'
  Sleep  1s
  END

Monitor Chassis
  [Documentation]  Calls Ping Chassis Status to and checks with a for loop that the chassis status is on
  FOR    ${INDEX}    IN RANGE    1   20
  Sleep   20s
  ${result} =    Run Process    ipmitool    -U  ${USER}     -P  ${PASSWORD}     -I  lanplus     -H  ${BMC_IP}    raw     6     1
  Log       ${result.stderr}
  Exit For Loop If    '${result.stderr}'!='Error: Unable to establish IPMI v2 / RMCP+ session'
  END

Change Redfish Password
  [Documentation]  Runs pass_change script to change the password of the redfish server
  ${result} =     Run Process    ./pass_change.sh    ${BMC_IP}
  Set Test Variable   ${redfish_error}       ${result.stderr}
  Should Be Empty     ${redfish_error}
  Log                 ${result.stdout}
  Run Keyword If     '${result.stdout}'=='Got 401 :( Password Change not yet successful'  Pass Execution  Password Already Changed!
  Run Keyword If     '${result.stdout}'!='Got 204! Password Change Successful'      Fail    Redfish Password Change not yet successful

Run UPNP Script
  [Documentation]  Runs upnp_discovery script to verify the ip address exists
  ${result} =     Run Process    ${EXECDIR}/upnp_discovery.sh   ${BMC_IP}    ${INTERFACE_NAME}
  Run Keyword If     '${result.stdout}'!='able to discover the Redfish Serice'      Fail    ${\n}${result.stdout}
  ...               ELSE  Pass Execution  ${\n}${result.stdout}

Run Redfish Firmware Update Script
  ${result} =    Run Process    ${EXECDIR}/redfish_firmware_update.sh    ${BMC_IP}  /home/suraj/gitlab_images/${IMAGE_FILE} 
  Log    ${result.stdout}
  @{output} =  Split String  ${result.stdout}  ${\n}
  ${post_firmware} =  Get From List  ${output}  0
  ${update_firmware} =  Get from List  ${output}  1
  Log  ${post_firmware}
  Log  ${update_firmware}
  Run Keyword If    '${post_firmware}'=='Post Firmware Image Successful'  Log To Console  ${\n}${post_firmware}
  ...               ELSE  Fail  ${\n}${post_firmware}
  Run Keyword If    '${update_firmware}'=='Update Firmware Image Successful'  Log To Console  ${\n}${update_firmware}
  ...               ELSE  Fail  ${\n}${update_firmware}

Start Time
  ${start} =  Get Current Date
  Set Global Variable    ${START}    ${start}

Stop Time
  ${stop} =   Get Current Date
  Set Global Variable    ${STOP}    ${stop}
  ${diff} =    Subtract Date From Date    ${STOP}  ${START}
  Log   ${diff}
  ${time} =  Convert Time  ${diff}  verbose
  Log To Console  ${\n}BOOT TIME: ${time}
