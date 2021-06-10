****** Settings ***
Documentation   This is NetCommander IP Power Strip resource file
Library         Process
Library         String
Library         Selenium2Library
Resource        webui.resource

*** Variables ***
${POWER_URL}                 ${EMPTY}
${POWER_USER}                admin
${POWER_PASS}                admin
${POWER_IP}                  172.31.1.106
${POWER_BUTTON}              //*[@id="display"]/table[1]/tbody/tr[6]/td[2]/a/img
${OUTLET_4_NAME_ID}          //*[@id="display"]/table[1]/tbody/tr[6]/td[5]
${OUTLET_4_STATUS_ID}        //*[@id="display"]/table[1]/tbody/tr[6]/td[4]/img
${POWER_STATUS}              ${EMPTY}



*** Keywords ***
Create URL
  ${URL1}=        Catenate    SEPARATOR=:    ${POWER_USER}  ${POWER_PASS}
  ${URL2}=        Catenate    SEPARATOR=@    ${URL1}        ${POWER_IP}
  ${URL2}=        Set Variable    http://${URL2}
  Set Global Variable  ${POWER_URL}  ${URL2}

Syncaccess Login
  Create URL
  Log                               ${POWER_URL}
  Open Chrome                       ${POWER_URL}
  ${name} =  Get Text               ${OUTLET_4_NAME_ID}

Power Status
  FOR   ${INDEX}  IN RANGE   1  50
  ${status} =  Run Keyword And Return Status  Get Element Attribute  ${OUTLET_4_STATUS_ID}   attribute=src
  Run Keyword If      '${status}'=='True'   Wait Until Keyword Succeeds    2m    1sec  Set Power Status
  Exit For Loop If    '${POWER_STATUS}'!='${EMPTY}'
  END

Set Power Status
  ${power} =   Get Element Attribute  ${OUTLET_4_STATUS_ID}   attribute=src
  Set Global Variable  ${POWER_STATUS}  ${power}

Execute Power Off
  Power Status
  FOR   ${INDEX}  IN RANGE   1  50
  Run Keyword If    '${POWER_STATUS}'=='${POWER_URL}/on.gif'   Click Element   ${POWER_BUTTON}
  Sleep  3s
  Power Status
  Exit For Loop If   '${POWER_STATUS}'=='${POWER_URL}/off.gif'
  END

Execute Power On
  Power Status
  FOR   ${INDEX}  IN RANGE   1  50
  Run Keyword If    '${POWER_STATUS}'=='${POWER_URL}/off.gif'   Click Element   ${POWER_BUTTON}
  Sleep  3s
  Power Status
  Exit For Loop If   '${POWER_STATUS}'=='${POWER_URL}/on.gif'
  END
