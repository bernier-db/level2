*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium
Library             RPA.Desktop
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library    RPA.Archive
Library    RPA.FileSystem


*** Variables ***
${URL}          https://robotsparebinindustries.com/#/robot-order
${FILE_URL}     https://robotsparebinindustries.com/orders.csv


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open Website
    ${orders}    Get Orders
    FOR    ${order}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${order}
        Store the receipt as a PDF file    ${order}[Order number]
        Start new order
    END
    Create Zip of receipts
    [Teardown]    Close Browser


*** Keywords ***
Open Website
    Open Available Browser    ${URL}

Get Orders
    ${orders_file}    Set Variable    ${OUTPUT_DIR}${/}orders.csv
    Download    ${FILE_URL}    overwrite=true    target_file=${orders_file}
    ${table}    Read table from CSV    ${orders_file}
    RETURN    ${table}

Close the annoying modal
    Click Button    I guess so...

Fill the form
    [Arguments]    ${order}
    ${order_number}    Set Variable    ${order}[Order number]
    ${head}    Set Variable    ${order}[Head]
    ${body}    Set Variable    ${order}[Body]
    ${legs}    Set Variable    ${order}[Legs]
    ${address}    Set Variable    ${order}[Address]

    Select From List By Value    id:head    ${head}
    Select Radio Button    body    ${body}
    Input Text    css:input[type=number]    ${legs}
    Input Text    id:address    ${address}

    Preview Robot
    Wait Until Keyword Succeeds    3x    200ms    Submit Order

Preview Robot
    Click Button    Preview

Submit Order
    Click Button    Order
    Assert Successful Submit

Assert Successful Submit
    Element Should Be Visible    id:receipt

Store the receipt as a PDF file
    [Arguments]    ${order_id}
    ${pdf_path}    Set Variable    ${OUTPUT_DIR}${/}receipts${/}${order_id}.pdf

    ${screenshot}    Screenshot    id:robot-preview-image
    ${html}    Get Element Attribute    id:receipt    outerHTML

    ${pdf}    Html To Pdf    ${html}    ${pdf_path}
    Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf_path}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    TRY
        ${file}    Open Pdf    ${pdf}
        Add Watermark Image To Pdf    ${screenshot}    ${pdf}
        Remove File    ${screenshot}
    FINALLY
        Close Pdf    ${pdf}
    END

Start new order
    Click Button    Order another robot

Create Zip of receipts
    Archive Folder With Zip    ${OUTPUT_DIR}/receipts    receipts.zip