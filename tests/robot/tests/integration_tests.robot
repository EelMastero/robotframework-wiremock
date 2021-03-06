*** Settings ***
Library  String
Library  Collections
Library  RequestsLibrary
Library  WireMockLibrary
Suite Setup  Create Sessions And Default Mappings
Test Teardown  Reset Wiremock


*** Variables ***
${WIREMOCK_URL}

${ENDPOINT}  /endpoint
&{BODY}  var1=value1  var2=value2
&{HEADERS}  Content-Type=application/json  Cache-Control=max-age\=3600

${MOCK_REQ}  {"method": "GET", "url": "${ENDPOINT}"}
${MOCK_RSP}  {"status": 200}
${MOCK_DATA}  {"request": ${MOCK_REQ}, "response": ${MOCK_RSP}}

*** Test Cases ***
Success On Expected GET
    &{req}=  Create Mock Request Matcher  GET  ${ENDPOINT}
    &{rsp}=  Create Mock Response  status=200
    Create Mock Mapping  ${req}  ${rsp}
    Send GET Expect Success  ${ENDPOINT}

Failure On GET With Mismatched Method
    Create Mock Mapping  ${DEF_GET_REQ}  ${DEF_GET_RSP}
    Send POST Expect Failure  ${ENDPOINT}

Failure On GET With Mismatched Endpoint
    Create Mock Mapping  ${DEF_GET_REQ}  ${DEF_GET_RSP}
    Send GET Expect Failure  /mismatched

Success On Expected GET With Path Pattern
    &{req}=  Create Mock Request Matcher  GET  /endpoint.*  url_match_type=urlPathPattern
    Create Mock Mapping  ${req}  ${DEF_GET_RSP}
    Send GET Expect Success  /endpoint-extended/api

Success On Expected GET With Query Parameter Matching
    &{match_params}=  Create Dictionary  param1=value1  param2=value2
    &{req}=  Create Mock Request Matcher  GET  ${ENDPOINT}  query_parameters=${match_params}
    Create Mock Mapping  ${req}  ${DEF_GET_RSP}
    Send GET Expect Success  ${ENDPOINT}  request_params=${match_params}

Failure On GET With Mismatched Query Parameters
    &{match_params}=  Create Dictionary  param1=value1  param2=value2
    &{mismatched_params}=  Create Dictionary  param1=mismatch  param2=value2
    &{req}=  Create Mock Request Matcher  GET  ${ENDPOINT}  query_parameters=${match_params}
    Create Mock Mapping  ${req}  ${DEF_GET_RSP}
    Send GET Expect Failure  ${ENDPOINT}  request_params=${mismatched_params}

Success On Expected GET With Query Parameter Regex Matching
    &{match_params}=  Create Dictionary  param=(.*)value[0-9]
    &{params}=  Create Dictionary  param=test-value9
    &{req}=  Create Mock Request Matcher  GET  ${ENDPOINT}
    ...                                   query_parameters=${match_params}
    ...                                   regex_matching=${True}
    Create Mock Mapping  ${req}  ${DEF_GET_RSP}
    Send GET Expect Success  ${ENDPOINT}  request_params=${params}

Success On Expected GET With Header Matching
    &{match_headers}=  Create Dictionary  header1=value1  header2=value2
    &{req}=  Create Mock Request Matcher  GET  ${ENDPOINT}  headers=${match_headers}
    Create Mock Mapping  ${req}  ${DEF_GET_RSP}
    Send GET Expect Success  ${ENDPOINT}  request_headers=${match_headers}

Failure On GET With Mismatched Header
    &{match_headers}=  Create Dictionary  header1=value1  header2=value2
    &{mismatched_headers}=  Create Dictionary  header1=mismatch  header2=value2
    &{req}=  Create Mock Request Matcher  GET  ${ENDPOINT}  headers=${match_headers}
    Create Mock Mapping  ${req}  ${DEF_GET_RSP}
    Send GET Expect Failure  ${ENDPOINT}  request_headers=${mismatched_headers}

Success On Expected GET With Cookie Matching
    &{match_cookies}=  Create Dictionary  cookie1=value1  cookie2=value2
    &{req}=  Create Mock Request Matcher  GET  ${ENDPOINT}  cookies=${match_cookies}
    Create Mock Mapping  ${req}  ${DEF_GET_RSP}
    Send GET Expect Success  ${ENDPOINT}

Failure On GET With Mismatched Cookies
    &{mismatched_cookies}=  Create Dictionary  cookie1=mismatched
    &{req}=  Create Mock Request Matcher  GET  ${ENDPOINT}  cookies=${mismatched_cookies}
    Create Mock Mapping  ${req}  ${DEF_GET_RSP}
    Send GET Expect Failure  ${ENDPOINT}

Success On Expected GET With Specified Data
    Create Mock Mapping With Data  ${MOCK_DATA}
    Send GET Expect Success  ${ENDPOINT}

Success On Expected GET With Status Message
    &{rsp}=  Create Mock Response  status=200  status_message=Ok
    Create Mock Mapping  ${DEF_GET_REQ}  ${rsp}
    Send GET Expect Success  ${ENDPOINT}  response_status_message=Ok

Success On Expected GET With Response Body
    &{rsp}=  Create Mock Response  status=200  headers=${HEADERS}  json_body=${BODY}
    Create Mock Mapping  ${DEF_GET_REQ}  ${rsp}
    Send GET Expect Success  ${ENDPOINT}  response_headers=${HEADERS}  response_body=${BODY}

Success On Expected POST With Body
    Create Mock Mapping  ${DEF_POST_REQ}  ${DEF_POST_RSP}
    Send POST Expect Success  ${ENDPOINT}  ${BODY}

Failure On POST With Mismatched Body
    Create Mock Mapping  ${DEF_POST_REQ}  ${DEF_POST_RSP}
    &{mismatched}=  Create Dictionary  var1=mismatch  var2=value2
    Send POST Expect Failure  ${ENDPOINT}  ${mismatched}

Failure On POST With Partial Body
    Create Mock Mapping  ${DEF_POST_REQ}  ${DEF_POST_RSP}
    &{partial}=  Create Dictionary  var1=value1
    Send POST Expect Failure  ${ENDPOINT}  ${partial}

Success On Default GET Mapping
    Create Default Mock Mapping  GET  ${ENDPOINT}
    Send GET Expect Success  ${ENDPOINT}

Success On Default GET Mapping With Response Body
    Create Default Mock Mapping  GET  /.*point.*  response_headers=${HEADERS}  response_body=${BODY}
    Send GET Expect Success  ${ENDPOINT}  response_headers=${HEADERS}  response_body=${BODY}

Success On Templated Response
    &{template_body}=  Create Dictionary  path_var={{request.path.[0]}}
    &{response_body}=  Create Dictionary  path_var=templated
    &{req}=  Create Mock Request Matcher  GET  /templated
    &{rsp}=  Create Mock Response  status=200  json_body=${template_body}  template=${True}
    Create Mock Mapping  ${req}  ${rsp}
    Send GET Expect Success  /templated  response_body=${response_body}

Requests Are Obtained For Path
    Create Mock Mapping  ${DEF_GET_REQ}  ${DEF_GET_RSP}
    Send GET Expect Success  ${ENDPOINT}
    Create Mock Mapping  ${DEF_POST_REQ}  ${DEF_POST_RSP}
    Send POST Expect Success  ${ENDPOINT}
    Create Default Mock Mapping  GET  /unmatched
    Send GET Expect Success  /unmatched

    @{reqs}=  Get Requests  ${ENDPOINT}
    ${count}=  Get Length  ${reqs}
    Should Be Equal As Strings  ${count}  2
    Should Be Equal As Strings  ${reqs[0]['url']}  ${ENDPOINT}
    Should Be Equal As Strings  ${reqs[0]['method']}  GET
    Should Be Equal As Strings  ${reqs[1]['url']}  ${ENDPOINT}
    Should Be Equal As Strings  ${reqs[1]['method']}  POST

Requests Are Obtained For Path And Method
    Create Mock Mapping  ${DEF_GET_REQ}  ${DEF_GET_RSP}
    Send GET Expect Success  ${ENDPOINT}
    Create Mock Mapping  ${DEF_POST_REQ}  ${DEF_POST_RSP}
    Send POST Expect Success  ${ENDPOINT}
    Create Default Mock Mapping  GET  /unmatched
    Send GET Expect Success  /unmatched

    @{reqs}=  Get Requests  ${ENDPOINT}  method=POST
    ${count}=  Get Length  ${reqs}
    Should Be Equal As Strings  ${count}  1
    Should Be Equal As Strings  ${reqs[0]['url']}  ${ENDPOINT}
    Should Be Equal As Strings  ${reqs[0]['method']}  POST

Previous Request Is Obtained For Path
    Create Mock Mapping  ${DEF_GET_REQ}  ${DEF_GET_RSP}
    Send GET Expect Success  ${ENDPOINT}
    Create Default Mock Mapping  GET  /unmatched
    Send GET Expect Success  /unmatched

    ${req}=  Get Previous Request  ${ENDPOINT}
    Should Be Equal As Strings  ${req['url']}  ${ENDPOINT}

Previous Request Body Is Obtained For Path
    Create Mock Mapping  ${DEF_POST_REQ}  ${DEF_POST_RSP}
    Send POST Expect Success  ${ENDPOINT}

    ${req_body}=  Get Previous Request Body  ${ENDPOINT}
    Should Be Equal As Strings  ${req_body}  ${BODY}
    Log  ${req_body}

*** Keywords ***
Create Sessions And Default Mappings
    &{match_cookies}=  Create Dictionary  cookie1=value1  cookie2=value2
    Create Session  server  ${WIREMOCK_URL}  cookies=${match_cookies}
    Create Mock Session  ${WIREMOCK_URL}

    &{DEF_GET_REQ}=  Create Mock Request Matcher  GET  ${ENDPOINT}
    &{DEF_GET_RSP}=  Create Mock Response  status=200
    &{DEF_POST_REQ}=  Create Mock Request Matcher  POST  ${ENDPOINT}  json_body=${BODY}
    &{DEF_POST_RSP}=  Create Mock Response  status=201
    Set Suite Variable  &{DEF_GET_REQ}
    Set Suite Variable  &{DEF_GET_RSP}
    Set Suite Variable  &{DEF_POST_REQ}
    Set Suite Variable  &{DEF_POST_RSP}

Reset Wiremock
    Reset Mock Mappings
    Reset Request Log

Send GET
    [Arguments]  ${endpoint}=${ENDPOINT}
    ...          ${request_params}=${None}
    ...          ${request_headers}=${None}
    ...          ${response_code}=200
    ${rsp}=  Get Request  server
    ...                   ${endpoint}
    ...                   params=${request_params}
    ...                   headers=${request_headers}
    Log  ${rsp.text}
    Should Be Equal As Strings  ${rsp.status_code}  ${response_code}
    [Return]  ${rsp}

Send GET Expect Success
    [Arguments]  ${endpoint}=${ENDPOINT}
    ...          ${request_params}=${None}
    ...          ${request_headers}=${None}
    ...          ${response_status_message}=${None}
    ...          ${response_headers}=${None}
    ...          ${response_body}=${None}
    ${rsp}=  Send GET  ${endpoint}  ${request_params}  ${request_headers}
    Run Keyword If   ${response_status_message != None}
    ...              Should Be Equal As Strings  ${response_status_message}  ${rsp.reason}
    Run Keyword If   ${response_headers != None}
    ...              Verify Response Headers  ${response_headers}  ${rsp.headers}
    Run Keyword If   ${response_body != None}
    ...              Verify Response Body  ${response_body}  ${rsp.json()}

Send GET Expect Failure
    [Arguments]  ${endpoint}=${ENDPOINT}
    ...          ${request_params}=${None}
    ...          ${request_headers}=${None}
    ...          ${response_code}=404
    Send GET  ${endpoint}  ${request_params}  ${request_headers}  ${response_code}

Send POST Expect Success
    [Arguments]  ${endpoint}=${ENDPOINT}  ${body}=${BODY}  ${response_code}=201
    Send POST  ${endpoint}  ${body}  ${response_code}

Send POST Expect Failure
    [Arguments]  ${endpoint}=${ENDPOINT}  ${body}=${BODY}  ${response_code}=404
    Send POST  ${endpoint}  ${body}  ${response_code}

Send POST
    [Arguments]  ${endpoint}  ${body}  ${response_code}
    ${body_json}=  Evaluate  json.dumps(${body})  json
    ${rsp}=  Post Request  server  ${endpoint}  data=${body_json}
    Should Be Equal As Strings  ${rsp.status_code}  ${response_code}

Verify Response Headers
    [Arguments]  ${expected}  ${actual}
    Dictionary Should Contain Sub Dictionary  ${actual}  ${expected}

Verify Response Body
    [Arguments]  ${expected}  ${actual}
    Dictionaries Should Be Equal  ${expected}  ${actual}
