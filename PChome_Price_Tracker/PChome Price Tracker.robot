*** Settings ***
Library    Collections
Library    OperatingSystem
Resource    ${EXECDIR}/keywords/reusedKeywords.txt

*** Test Cases ***
Track PChome product Prices
    Go To Tracking List
    Login
    Wait Until Tracking List Page Is Visible
    @{productList} =    Crawl PChome Product Tracking List
    @{productList} =    Remove Unavailable Product    ${productList}
    Close Browser
    @{sendList}    Create Or Update Database    ${productList}
    Run Keyword Unless    ${sendList} == @{EMPTY}    Send Discount Notification Mail To User    ${sendList}

*** Keywords ***
Go To Tracking List
    Open Browser    https://ecvip.pchome.com.tw/web/MemberProduct/Trace    Chrome    options=add_argument("--disable-notifications")
    Maximize Browser Window

Login
    ${userField} =    Set Variable    //*[@id='loginAcc']
    ${passwordField} =    Set Variable    //*[@id='loginPwd']
    ${keepBtn} =    Set Variable    //*[@id='btnKeep']
    ${loginBtn} =    Set Variable    //*[@id='btnLogin']
    Input Text After It Is Visible    ${userField}    ${userInfo}[userID]
    Click Element After It Is Visible    ${keepBtn}
    Input Text After It Is Visible    ${passwordField}    ${userInfo}[password]
    Click Element After It Is Visible    ${loginBtn}

Wait Until Tracking List Page Is Visible
    ${trackingListPage} =    Set Variable    //*[@id = 'traceData']
    Wait Until Page Contains Element    ${trackingListPage}    timeout=${shortPeriodOfTime}    error=Element should be visible.\n${trackingListPage}
    Wait Until Element Is Visible    ${trackingListPage}    timeout=${shortPeriodOfTime}    error=Element should be visible.\n${trackingListPage}

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
        ${name} =    Evaluate     "".join(char for char in '${name}' if ord(char) < 65536)
        ${price} =    Evaluate    '${price}'.replace('$','')
        ${status} =    Run Keyword And Return Status    Page Should Not Contain Element    (//*[contains(@class, 'site_btn')])[${index}+1][contains(@class,'soldOut')]
        &{product} =    Create Dictionary    name=${name}    price=${price}    link=${link}    image=${image}    status=${status}
        Append To List    ${products}    ${product}
    END
    ${btnExist}    Run Keyword And Return Status    Element Should Be Visible    ${nextPageBtn}
    Run Keyword If    ${btnExist}    Run Keywords    Click Element After It Is Visible    ${nextPageBtn}
    ...                                       AND    Get Products Information    ${products}
    [Return]    @{products}

Wait Until Product List Is Visible
    ${item} =    Set Variable    //*[contains(@class, 'itemRow')]
    Wait Until Page Contains Element    ${item}    timeout=${shortPeriodOfTime}    error=Element should be visible.\n${item}
    Wait Until Element Is Visible    ${item}    timeout=${shortPeriodOfTime}    error=Element should be visible.\n${item}

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
    Wait Until Page Does Not Contain Element    //*[contains(@class, 'itemRow')]//u[normalize-space()='${name}']

Create Or Update Database
    [Arguments]    ${products}
    ${fileExist}    Run Keyword And Return Status    File Should Exist    ${EXECDIR}/database/Price Tracking List.csv
    Run Keyword And Return If    ${fileExist}    Compare And Update Database    ${products}
    Create Database    ${products}