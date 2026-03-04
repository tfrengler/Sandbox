<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8" />
    <title>CfSandbox</title>

    </head>
    <body>

        <cfscript>
            Playwright = createObject("java", "com.microsoft.playwright.Playwright");
            playwright = Playwright.create();
            browser = playwright.chromium().launch();
            page = browser.newPage();
            page.navigate("https://nu.nl");
            writeOutput("Page title: " & page.title());
            browser.close();
            playwright.close();
        </cfscript>

    </body>
</html>