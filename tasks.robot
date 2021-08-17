*** Settings ***
Documentation   To complete the second Task
...             and confirm sufficient understanding and familiarization
...             Good Luck to me!
Library         RPA.HTTP
Library         RPA.Browser
Library         RPA.Tables
Library         RPA.PDF
Library         RPA.Archive
Library         RPA.Dialogs
Library         RPA.Robocloud.Secrets


*** Variables ***
${receiptPath}=  ${CURDIR}${/}output${/}receipts

*** Keywords ***
Download the Orders File
    ${FileDownloadPath}=  Get Secret  robotsparebin
    #Download  https://robotsparebinindustries.com/orders.csv  target_file=${CURDIR}${/}output${/}orders.csv   overwrite=True
    Download  ${FileDownloadPath}[source_file_path]  target_file=${CURDIR}${/}output${/}orders.csv   overwrite=True


*** Keywords ***
Open Browser and Launch Website
    Open Available Browser  https://robotsparebinindustries.com/#/robot-order

*** Keywords ***
Handle Launch Pop Up
    [Arguments]  ${popUpResponse}
    Wait Until Page Contains Element    css:BUTTON.btn.btn-dark
    Click Button    ${popUpResponse}

*** Keywords ***
Select Option for Order
    [Arguments]  ${order}
    Select From List By Value    id:head  ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${order}[Legs]
    Input Text    id:address    ${order}[Address]

*** Keywords ***
Preview and snap the bot
    [Arguments]  ${orderNumber}
    [Return]     ${botPreview}
    Click Button    id:preview
    #Wait Until Element Is Visible  id:robot-preview-image  timeout=5
    Wait Until Element Is Visible  css:IMG:nth-child(1)  timeout=5
    Wait Until Element Is Visible  css:IMG:nth-child(2)  timeout=5
    Wait Until Element Is Visible  css:IMG:nth-child(3)  timeout=5
    Screenshot  id:robot-preview-image  ${CURDIR}${/}output${/}${orderNumber}.png
    ${botPreview}  Set Variable  ${CURDIR}${/}output${/}${orderNumber}.png
    #Log  ${botPreview}

*** Keywords ***
Submit Order
    #Wait Until Keyword Succeeds    3x    0.5 sec   Submit Order
    #Wait Until Keyword Succeeds    3x    0.5 sec    Click Button    id:order
    Click Button    id:order
    Wait Until Page Contains Element  id:receipt

*** Keywords ***
Get Order details
    [Return]  ${pdfReceipt}
    Wait Until Page Contains Element  id:receipt
    ${pdfReceipt}=  Get Text    id:receipt

*** Keywords ***
Create the pdf receipt
    [Arguments]  ${pdfReceipt}  ${botPreview}  ${orderNumber}
    Html To Pdf    ${pdfReceipt}    ${receiptPath}${/}${orderNumber}.pdf
    Open Pdf  ${receiptPath}${/}${orderNumber}.pdf
    Add Watermark Image To Pdf  ${botPreview}  ${receiptPath}${/}${orderNumber}.pdf
    Close Pdf  ${receiptPath}${/}${orderNumber}.pdf

*** Keywords ***
Navigate to Order Page
    Wait Until Page Contains Element  id:order-another
    Click Button    id:order-another

*** Keywords ***
Convert all receipts to zip
    Archive Folder With Zip    ${receiptPath}    receipts.zip

*** Keywords ***
Final Close Browser
    Close Browser

*** Keywords ***
Pop Up Option Selection
    Add heading  Give up your rights!
    Add drop-down   userInput  OK,Yep,I guess so..., No way!  default=OK
    ${popUpResponse}=    Run dialog
    Log  ${popUpResponse.userInput}
    [Return]  ${popUpResponse.userInput}
    #[Return]    ${response.search}

*** Keywords ***
Test Key
    Open Available Browser  https://robotsparebinindustries.com/#/robot-order
    
    Wait Until Page Contains Element    css:BUTTON.btn.btn-dark
    Click Button    OK
    
    Select From List By Value    id:head  1
    Select Radio Button    body    5
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    4
    Input Text    id:address    addr123test

    Click Button    id:preview
    #Wait Until Element Is Visible  id:robot-preview-image  timeout=5
    Wait Until Element Is Visible  css:IMG:nth-child(1)  timeout=5
    Wait Until Element Is Visible  css:IMG:nth-child(2)  timeout=5
    Wait Until Element Is Visible  css:IMG:nth-child(3)  timeout=5
    Screenshot  id:robot-preview-image  ${CURDIR}${/}output${/}$test123.png


*** Tasks ***
Order Processing Bot
    Download the Orders File
    Open Browser and Launch Website
    ${popUpResponse}=  Pop Up Option Selection
    ${orders}=   Read Table From Csv  ${CURDIR}${/}output${/}orders.csv
    FOR    ${order}    IN    @{orders}
        Handle Launch Pop Up  ${popUpResponse}
        Select Option for Order  ${order}
        ${botPreview}=  Preview and snap the bot  ${order}[Order number]
        Wait Until Keyword Succeeds    3 min    5 sec   Submit Order
        #BuiltIn.Wait Until Keyword Succeds  3x  0.5  Submit Order
        ${pdfReceipt}=  Get Order details
        Create the pdf receipt  ${pdfReceipt}  ${botPreview}  ${order}[Order number]
        Navigate to Order Page
        Log  ${order}[Address]
    END
    Convert all receipts to zip
    [Teardown]  Final Close Browser


