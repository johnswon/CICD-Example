*** Settings ***
Documentation   This library will be used to get fw, image signing tool and yafu flash from the users runner OR from ftp
Resource        ${CURDIR}/webui.resource
Library         Process
Library         String
Library         Collections
Library         OperatingSystem
Library         Selenium2Library

*** Variables ***
${BMC_IP}          172.31.1.106
${TEST_FAILED}     //div[@class="card text-white card-info"]
${RESULTS_PATH}    ./../results

*** Keywords ***
Newman Teardown
  Remove File       ${RESULTS_PATH}/Redfish*
  Move File         newman/Redfish*  ${RESULTS_PATH}
  Close Browser


Run Newman Tests
  [Documentation]  Runs newman command to run the postman_collection.json
  Remove Directory  newman  recursive=True
  Run Process    newman  run  -k  --ignore-redirects  -e  ${EXECDIR}/Newman/env_2019.2.json  --reporters  htmlextra  ${EXECDIR}/Newman/Redfish-BVT-Criteria.postman_collection.json
  @{file} =  List Files In Directory    ${EXECDIR}/newman/   Redfish*
  ${path} =   Evaluate  "/".join($file)
  Log  ${path}
  ${absolute_path} =  Join Path      ${EXECDIR}/newman/    ${path}
  Log   ${absolute_path}
  Open Chrome   file://${absolute_path}
  ${text} =  Get Text   ${TEST_FAILED}
  Log   ${text}
  @{string} =   Split String    ${text}
  ${value} =    Get From List   ${string}    3
  Log    ${value}
  Newman Teardown
  Run Keyword If    '${value}'!='0'    Fail  ${\n}Newman Total Tests Failed: ${value}
  Pass Execution     ${\n}Newman Tests Passed
