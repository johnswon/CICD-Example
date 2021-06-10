*** Settings ***
Documentation   Resource File for MegaRac SP-X WebUI
Library         Selenium2Library  timeout=20
Library         String

*** Variables ***
${BMC_IP}                  172.31.1.106
${BROWSER_URL}             https://${BMC_IP}/
${ADVANCED}                id:details-button
${PROCEED_LINK}            id:proceed-link
${MEGARAC_SIGN_IN_HEADER}  megarac sp-x
${USERNAME_SPX}            admin
${PASSWORD_SPX}            admin123
${USERNAME_FIELD}          id:userid
${PASSWORD_FIELD}          id:password
${SIGN_ME_IN}              id:btn-login
${REMOTE_CONTROL_TAB}      //a[@href="#remote_control"]
${SYSTEM_INVETORY_TAB}     //a[@href="#system_inventory_info"]
${PROCESSOR_TAB}           id:processor-tab
${MEMORY_CONTROLLER_TAB}   id:memory-tab
${PCIE_DEVICE_TAB}         id:pciedevice-tab
${PCIE_FUNCTION_TAB}       id:pciefunction-tab
${STORAGE_TAB}             id:storage-tab
${PROCESSOR_ELEM}          //td[@class="dimmtd"]
${MEMORY_ELEM}             (//td[@class="dimmtd"])[2]
${PCIE_DEVICE_ELEM}        (//td[@class="dimmtd"])[3]
${PCIE_FUNCTION_ELEM}      (//td[@class="dimmtd"])[4]
${STORAGE_ELEM}            (//td[@class="dimmtd"])[5]
${PAGE_COUNT_NO_INFO}      ${0}
${LAUNCH_H5VIEWER}         id:download
${ADMIN_AVATAR}            //span[@class="username"]
${LOGOUT}                  //a[@href="#logout"]
${FIRMWARE_UPDATE_IMAGE}   ./encrypted_wolfpass_64_k5.ima_enc

*** Keywords ***
Open Chrome
  [Documentation]  Chrome options running with Selenium2Library
  [Arguments]    ${url}
  ${chrome_options} =   Evaluate    sys.modules['selenium.webdriver'].ChromeOptions()    sys, selenium.webdriver
  ${ws} =               Set Variable    window-size=1920,1080
  Call Method           ${chrome_options}    add_argument    --disable-extensions
  Call Method           ${chrome_options}    add_argument    --headless
  Call Method           ${chrome_options}    add_argument    --disable-gpu
  Call Method           ${chrome_options}    add_argument    --no-sandbox
  Call Method           ${chrome_options}    add_argument    --ignore-certificate-errors
  Call Method           ${chrome_options}    add_argument    --disable-dev-shm-usage
  Call Method           ${chrome_options}    add_argument    ${ws}
  Create Webdriver      Chrome    chrome_options=${chrome_options}
  Go To                 ${url}

Browser Setup
  [Documentation]  Test setup for MegaRac-Spx Browser
  Open Chrome  ${BROWSER_URL}
  ${read}=     Get Location
  Log  ${read}
  ${read}=    Get Title
  Log  ${read}
  Sign In

Sign In
  [Documentation]  Sign in Keyword signs into MegaRac-Spx Web GUI Sign in page
  ${title} =   Get Title
  Log   ${title}
  ${result} =   Convert To Lowercase  ${title}
  Evaluate    '${result}'=='${MEGARAC_SIGN_IN_HEADER}'
  Wait Until Element Is Enabled  ${USERNAME_FIELD}
  Input Text  ${USERNAME_FIELD}  ${USERNAME_SPX}
  Input Text  ${PASSWORD_FIELD}  ${PASSWORD_SPX}
  Wait Until Element Is Enabled  ${SIGN_ME_IN}
  Click Element                  ${SIGN_ME_IN}
  Prevent Processing Element

Browser Teardown
  [Documentation]  Test Teardown signs out of MegaRac-SPX GUI: Must be called from MegaRac SPX Dashboard
  Click Element    ${ADMIN_AVATAR}
  Click Link       ${LOGOUT}
  Handle Alert     action=ACCEPT
  ${title} =   Get Title
  Log   ${title}
  ${result} =   Convert To Lowercase  ${title}
  Evaluate    '${result}'=='${MEGARAC_SIGN_IN_HEADER}'
  Close Browser

Check System Information Tab
  [Documentation]  Selects System Information Tab and checks the information displayed on each tabs
  Wait and Click                ${SYSTEM_INVETORY_TAB}
  Wait Until Element Is Visible  ${PROCESSOR_TAB}
  Wait Until Element Is Enabled  ${PROCESSOR_TAB}
  Wait and Click                 ${PROCESSOR_TAB}
  If Element is Visible          ${PROCESSOR_ELEM}
  Wait and Click                 ${MEMORY_CONTROLLER_TAB}
  If Element is Visible          ${MEMORY_ELEM}
  Wait and Click                 ${PCIE_DEVICE_TAB}
  If Element is Visible          ${PCIE_DEVICE_ELEM}
  Wait and Click                 ${PCIE_FUNCTION_TAB}
  If Element is Visible          ${PCIE_FUNCTION_ELEM}
  Wait and Click                 ${STORAGE_TAB}
  If Element is Visible          ${STORAGE_ELEM}
  Log  Number of Pages with Information Not Available: ${PAGE_COUNT_NO_INFO}
  ${PASSED_COUNT}=               Evaluate    ${5}-${PAGE_COUNT_NO_INFO}
  Run Keyword If  ${PAGE_COUNT_NO_INFO}==5  Fail  No Information is Available
  ...             ELSE  Pass Execution
  ...                     ${\n}Information is available on ${PASSED_COUNT}/5 tabs

Wait and Click
  [Documentation]  Wait and Click takes in a link/element and verifies it exists before Selneium Library clicks
  [Arguments]   ${link}
  Wait Until Element Is Enabled  ${link}
  Wait Until Keyword Succeeds    2 min  5 sec
  ...                            Click Element  ${link}

If Element is Visible
  [Documentation]  Keyword takes in a text and verify if it exists on the current page and increments a counter
  [Arguments]   ${element}
  ${status} =  Run Keyword And Return Status   Wait Until Element Contains   ${element}  Information Not Available
  Run Keyword If  '${status}'=='True'  Pages Contain No Info

Pages Contain No Info
  [Documentation]  Keyword is called by If Element is Visible, it increments the global variable ${var} by 1
  ${var} =  Evaluate   ${PAGE_COUNT_NO_INFO}+${1}
  Set Global Variable  ${PAGE_COUNT_NO_INFO}  ${var}

KVM Page
  [Documentation]  Keyword checks if KVM is dispalyed on the Remote Control Page
  Wait and Click   ${REMOTE_CONTROL_TAB}
  Wait and Click   ${LAUNCH_H5VIEWER}
  Pass Execution   KVM Page Was Found

Prevent Processing Element
    Wait Until Element Is Not Visible   xpath=(//div[@id="processing_layout"])    timeout=90   error=processing_layout

Goto Firmware Update Page
    Go to    ${BROWSER_URL}#maintenance/firmware_update_wizard

Goto Firmware Update Page and Choose Image File
  Goto Firmware Update Page
  Prevent Processing Element
  Choose File                                 //input[@id="mainfirmware_image"]              ${FIRMWARE_UPDATE_IMAGE}
  Click Element                               //button[@id="btnFirmwareChecks"]
  Prevent Processing Element

Start Firmware Update Process
  Save And Handle Alert                       //*[@id="proceed"]                        Accept
  Handle Alert                                action=ACCEPT                                  timeout=150s
  ${text}=    Get Text                        //*[@id="upload_progress"]/span
  Should Be True    '${text}'=='Flashing (100% done)' or '${text}'=='Flashing (100% done )'
  Sleep                                       5
