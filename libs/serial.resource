*** Settings ***
Documentation   Resource File for Redfish Serial BMC
Resource        ${CURDIR}${/}bvt.resource
Library         SerialLibrary      encoding=ascii
Library         String
Library         Collections
Library         Process

*** Variables ***
${PORT}             /dev/ttyUSB3
${ASK_PASSWORD}     Password:
${USERNAME_SERIAL}  sysadmin
${PASSWORD_SERIAL}  superuser
${PROMPT}           ~ #
${PSAXGREPLUA}      ps ax | grep lua
${DFH}              df -h
${MOUNT_POINT}      /conf
${IFCONFIG}         ifconfig

*** Keywords ***

Open Serial Port
  [Documentation]  Adds port to the test suite and opens it for test setup
  Run Process    sudo  chmod  777  ${PORT}
  Add Port   ${PORT}
  ...        baudrate=115200
  ...        bytesize=8
  ...        parity=N
  ...        stopbits=1
  ...        timeout=30
  Open Port
  Port Should Be Open

Close All Ports
  [Documentation]  Exits the prompt and closes the serial port
  Write Data    exit\r
  ${read} =     SerialLibrary.Read Until
  Log  ${read}
  Close Port
  Port Should Be Closed

Login Serial
  [Documentation]  Writes in the username and password to an active serial
  Write Data       \r
  ${read} =        SerialLibrary.Read Until
  Write Data       ${USERNAME_SERIAL}\r
  ${read} =        SerialLibrary.Read Until      terminator=${ASK_PASSWORD}
  Should Contain   ${read}        ${ASK_PASSWORD}
  Log              ${read}
  Write Data       ${PASSWORD_SERIAL}\r
  ${read} =        SerialLibrary.Read Until      terminator=${PROMPT}
  Should Contain   ${read}        ${PROMPT}
  Log              ${read}

Find All Lua Processes
  [Documentation]  Writes command and verifies all lua processes are found in the output
  Write Data           ${PSAXGREPLUA}\r
  ${read} =            SerialLibrary.Read Until
  Log                  ${read}
  ${read} =            SerialLibrary.Read Until    terminator=${PROMPT}
  Log                  ${read}
  Should Match Regexp  ${read}     .*luajit\\sagent.lua
  Should Match Regexp  ${read}     .*redfish-2-redfishgroup.lua
  Should Match Regexp  ${read}     .*redfishgroup-2-fns.lua
  Should Match Regexp  ${read}     .*telemetry.lua
  Should Match Regexp  ${read}     .*task-service.lua
  Should Match Regexp  ${read}     .*event-service.lua
  Should Match Regexp  ${read}     .*server.lua
  Log                  ${read}
  Pass Execution       All Lua Processes Found

Verify Harddisk Size is >= 1.5M
  [Documentation]  Writes "df -h" to serial and looks for the size of the mount point
  Write Data           ${DFH}\r
  ${read} =            SerialLibrary.Read Until   ${PROMPT}
  Log                  ${read}   formatter=str
  Should Match Regexp  ${read}   .*${MOUNT_POINT}.*
  ${read} =        Get Lines Matching Pattern  ${read}  *${MOUNT_POINT}*
  Log  ${read}
  # Strips string to find size of the filesystem
  @{words} =       Split String   ${read}  ${SPACE}  1
  ${string} =      Get From List  ${words}  1
  ${filesystem} =  Get From List  ${words}  0
  ${words} =       Split String   ${string}
  ${size} =        Get From List  ${words}  0
  Log  ${size}
  Log  ${filesystem}
  ${status} =  Run Keyword And Return Status  Should Contain  ${size}  M
  Run Keyword if  '${status}'=='True'  Get Harddrive Size  ${size}  ${filesystem}
  ...             ELSE  Fail  ${filesystem} size of ${size} is less than 1.5M

Get Harddrive Size
  [Documentation]  Keyword called when size is greater than 999K and compares it to 1.5M
  [Arguments]  ${size}  ${filesystem}
  ${float} =    Get Substring  ${size}  0  -1
  Convert To Number     ${float}
  ${status} =   Evaluate  ${float}>=1.5
  Run Keyword If  '${status}'=='False'
  ...               Fail  ${filesystem} size of ${size} is less than 1.5M
  ...             ELSE  Pass Execution
  ...               ${\n}${filesystem} size of ${size} is greater than or equal to 1.5M

Set IP Address
  [Documentation]  Keyword parses for correct ip address and passes it as a global variable
  Write Data           ifconfig\r
  ${read} =            SerialLibrary.Read Until   ${PROMPT}
  Log                  ${read}  formatter=str
  #Looks for possible host interfaces and sets type to most recent one founded
  Find Interface  ${read}    bond0
  Find Interface  ${read}    eth1
  Find Interface  ${read}    eth0
  Log     ${type}
  #Splits string from type to ensure the first inet addr found belongs to the type
  @{word} =  Split String  ${read}    ${type}
  Log     ${word}     formatter=str
  ${test} =   Get From List    ${word}  1
  Log   ${test}
  ${read} =            Get Lines Matching Pattern  ${read}  *inet addr:*
  Log                  ${read}
  ${read} =            Remove String    ${read}    inet addr:
  #Logs all inet addresses after the most recent type
  Log                  ${read}
  @{ip} =  Create List
  #For loop splits the ip addresss from the lines
  @{lines} =           Split To Lines    ${read}
  FOR            ${line}   IN           @{lines}
  @{split} =    Split String    ${line}
  ${split} =    Get From List   ${split}    0
  ${status} =   Run Keyword And Return Status  Should Not Contain Any    ${split}    169   127
  Run Keyword If    '${status}'=='True'   Append To List    ${ip}    ${split}
  END
  Log        ${ip}
  # Gets first ip address from that list as it belongs to the most recent type
  ${ipaddr} =   Get From List  ${ip}  0
  Set Global Variable    ${BMC_IP}    ${ipaddr}
  Set Global Variable    ${BROWSER_URL}    https://${BMC_IP}/
  ${result} =    Run Process    python3  ./env_parse.py    ${BMC_IP}
  Log                    ${\n}${result.stdout}
  Pass Execution         ${\n}IP Address Configured To ${BROWSER_URL}

Find Interface
  [Documentation]  Keyword called to parse through a text and look for Host Interfaces
  [Arguments]     ${string}  ${var}
  ${status}=  Run Keyword and Return Status  Should Contain    ${string}    ${var}
  Run Keyword If    '${status}'=='True'    Set Global Variable    ${type}    ${var}
  ...               ELSE            Set Global Variable    ${type}    ${EMPTY}

Verify Serial Login Prompt
  FOR    ${INDEX}    IN RANGE    1   120
  Sleep  5s
  Write Data     \r
  ${login} =  SerialLibrary.Read Until   terminator=login:
  Log  ${login}
  ${status} =  Run Keyword And Return Status    Should Contain    ${login}    login:
  Exit For Loop If  '${status}'=='True'
  END

Check U-Boot
  ${uboot} =  SerialLibrary.Read Until  terminator=U-Boot
  Log   ${uboot}

Check Redfish Firmware Update Successful
  ${flash} =  SerialLibrary.Read Until  terminator=Flash All Complete!!
  Log   ${flash}
