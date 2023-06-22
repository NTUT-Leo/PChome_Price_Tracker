*** Settings ***
Library    Collections
Library    OperatingSystem
Resource    ${EXECDIR}/keywords/reusedKeywords.txt
Test Setup    Wait Until Keyword Succeeds    ${retry}    0s    Go To Tracking List    fakeDevice=${True}
Test Teardown    Close Browser

*** Test Cases ***
Track PChome product Prices
    Wait Until Keyword Succeeds    ${retry}    0s    Login
    @{productList} =    Crawl PChome Product Tracking List
    @{productList} =    Remove Unavailable Product    ${productList}
    @{sendList} =    Create Or Update Database    ${productList}
    Run Keyword Unless    ${sendList} == @{EMPTY}    Send Discount Notification Mail To User    ${sendList}

*** Keywords ***
Go To Tracking List
    [Arguments]    ${fakeDevice}=${False}    ${proxy}=${False}
    ${url} =    Set Variable    https://ecvip.pchome.com.tw/web/MemberProduct/Trace
    ${userAgent} =    Run Keyword If    ${fakeDevice}    Generate User Agent
    ${chromeOptions} =    Set Variable If    ${fakeDevice}    ${chromeOptions}; add_argument("user-agent=${userAgent}")    ${chromeOptions}
    ${chromeOptions} =    Set Variable If    ${proxy}    ${chromeOptions}; add_argument("--proxy-server=socks5://localhost:9050")    ${chromeOptions}
    Close Browser
    Run Keyword If    '${{platform.system()}}' == 'Windows'    Open Browser    ${url}    Chrome    options=${chromeOptions}
    ...    ELSE IF    '${{platform.system()}}' == 'Linux'    Open Browser    ${url}    Chrome    options=${chromeOptions}; add_argument("--no-sandbox")
    Maximize Browser Window
    ${forbidden} =    Run Keyword And Return Status    Title Should Be    403 Forbidden
    Wait Until Login Page Is Visible
    [Teardown]    Run Keyword If    ${forbidden}    Run Keywords    Switch IP
    ...                                                      AND    Sleep    ${normalPeriodOfTime}

Wait Until Login Page Is Visible
    ${loginPage} =    Set Variable    //*[@id='memLogin']
    Wait Until Page Contains Element    ${loginPage}    timeout=${normalPeriodOfTime}    error=Element should be visible.\n${loginPage}
    Wait Until Element Is Visible    ${loginPage}    timeout=${normalPeriodOfTime}    error=Element should be visible.\n${loginPage}

Login
    ${reCAPTCHA} =    Set Variable    //*[@id='recaptcha_checkLoginAcc']//iframe[@title='reCAPTCHA']
    ${default} =    Set Selenium Speed    0.6s
    Input Text After It Is Visible    //*[@id='loginAcc']    ${userInfo}[userID]
    Click Element After It Is Visible    //*[@id='btnKeep']
    ${detection} =    Run Keyword And Return Status    Wait Until Element Is Visible    ${reCAPTCHA}    timeout=${shortPeriodOfTime}    error=Element should be visible.\n${reCAPTCHA}
    Input Text After It Is Visible    //*[@id='loginPwd']    ${userInfo}[password]
    Click Element After It Is Visible    //*[@id='btnLogin']
    ${detection} =    Run Keyword And Return Status    Wait Until Element Is Visible    ${reCAPTCHA}    timeout=${shortPeriodOfTime}    error=Element should be visible.\n${reCAPTCHA}
    Set Selenium Speed    ${default}
    Wait Until Tracking List Page Is Visible
    [Teardown]    Run Keyword If    ${detection}    Run Keywords    Switch IP
    ...                                                      AND    Sleep    ${normalPeriodOfTime}
    ...                                                      AND    Wait Until Keyword Succeeds    ${retry}    0s    Go To Tracking List    fakeDevice=${True}

Wait Until Tracking List Page Is Visible
    ${trackingListPage} =    Set Variable    //*[@id = 'traceData']
    Wait Until Page Contains Element    ${trackingListPage}    timeout=${longPeriodOfTime}    error=Element should be visible.\n${trackingListPage}
    Wait Until Element Is Visible    ${trackingListPage}    timeout=${longPeriodOfTime}    error=Element should be visible.\n${trackingListPage}

Crawl PChome Product Tracking List
    @{products} =    Create List
    ${hasItem} =    Run Keyword And Return Status    Element Should Not Contain    //*[@id='noItem']    尚未追蹤任何商品!
    Run Keyword And Return If    ${hasItem}    Get Products Information    ${products}
    [Return]    @{products}

Get Products Information
    [Arguments]    ${products}
    ${item} =    Set Variable    //*[contains(@class, 'itemRow')]
    ${nextPageBtn} =    Set Variable    //*[@id='next_page']
    Wait Until Product List Is Visible
    Scroll To Bottom
    ${rows} =    Get Element Count    ${item}
    FOR    ${index}    IN RANGE    ${rows}
        ${name} =    Get Text After It Is Visible    (${item}//u)[${index}+1]
        ${price} =    Get Text After It Is Visible    (//*[@class='IT_PRICE'])[${index}+1]
        ${link} =    Get Element Attribute After It Is Visible    (${item}//*[@class='text13']//a)[${index}+1]    href
        ${image} =    Get Element Attribute After It Is Visible    (//*[@class='prodpic']//img)[${index}+1]    src
        ${name} =    Evaluate     ''.join(char for char in '${name}' if ord(char) < 65536)
        ${price} =    Evaluate    '${price}'.replace('$','')
        ${status} =    Run Keyword And Return Status    Element Should Not Be Visible    (//*[contains(@class, 'site_btn')])[${index}+1][contains(@class,'soldOut')]
        &{product} =    Create Dictionary    name=${name}    price=${price}    link=${link}    image=${image}    status=${status}
        Append To List    ${products}    ${product}
    END
    ${btnExist} =    Run Keyword And Return Status    Element Should Be Visible    ${nextPageBtn}
    Run Keyword And Return If    ${btnExist}    Run Keywords    Click Element After It Is Visible    ${nextPageBtn}
    ...                                                  AND    Get Products Information    ${products}
    [Return]    @{products}

Remove Unavailable Product
    [Arguments]    ${products}
    ${inputField} =    Set Variable    //*[@id='keyword']
    ${searchBtn} =    Set Variable    //*[@id='doSearch']
    ${deleteBtn} =    Set Variable    //*[contains(@id, 'delete')]
    ${showAllBtn} =    Set Variable    //*[@id='showAll']
    @{fineProduct} =    Create List
    FOR    ${product}    IN    @{products}
        Run Keyword If    not ${product}[status]    Run Keywords    Input Text After It Is Visible    ${inputField}    ${product}[name]
        ...                                                  AND    Click Element After It Is Visible    ${searchBtn}
        ...                                                  AND    Wait Until Product List Is Visible
        ...                                                  AND    Click Element After It Is Visible    ${deleteBtn}
        ...                                                  AND    Wait Until Product Is Deleted    ${product}[name]
        ...                                                  AND    Click Element After It Is Visible    ${showAllBtn}
        ...       ELSE    Append To List    ${fineProduct}    ${product}
    END
    [Return]    @{fineProduct}

Wait Until Product Is Deleted
    [Arguments]    ${name}
    Wait Until Element Is Not Visible    //*[contains(@class, 'itemRow')]//u[normalize-space()='${name}']    timeout=${normalPeriodOfTime}    error=Element should not be visible.\n${name}

Create Or Update Database
    [Arguments]    ${products}
    ${fileExist} =    Run Keyword And Return Status    File Should Exist    ${EXECDIR}/database/Price Tracking List.csv
    Run Keyword And Return If    ${fileExist}    Compare And Update Database    ${products}
    Create Database    ${products}