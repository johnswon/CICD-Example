*** Settings ***
Documentation
Library         Process
Library         String
Library         Collections
Library         OperatingSystem

*** Variables ***
${BMC_IP}          172.31.1.106

*** Keywords ***
Redfish Service Validator Run
  Run  rm -rf logs
  ${result} =   Run  python3 ./Redfish-Service-Validator/RedfishServiceValidator.py --csv_report --ip ${BMC_IP} -c ./Redfish-Service-Validator/config.ini
  Log  ${result}
  ${str} =     Get Lines Matching Pattern    ${result}   Validation has failed*
  @{array} =    Split String  ${str}
  ${number} =  Get From List  ${array}  3
  Run Keyword If    '${number}'!='0'   Fail  ${str}

Redfish Service Validator Clean Up
  Move Files  ./logs/*.html  ../results
  Remove Directory  ./logs  recursive=True
