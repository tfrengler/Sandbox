<cfset OS = createObject("java", "java.lang.System").getProperty("os.name").toLowerCase() />
<cfset IS_WINDOWS = (find("win", OS) GT 0) />
<cfset IS_MAC = (find("mac", OS) GT 0) />
<cfset IS_UNIX = (find("nix", OS) GT 0 OR find("nux", OS) GT 0 OR find("aix", OS) GT 0) />

<cfset ValidBrowsers = ["CHROME","FIREFOX"] />
<cfset ValidArchitectures = ["x64","x86"] />
<cfset ValidPlatforms = ["WINDOWS","LINUX"] />

<cfset DriverNames = {
    "FIREFOX": "geckodriver",
    "CHROME": "chromedriver",
    "EDGE": ""
} />

<cfset BrowserLatestVersionURLs = {
    "CHROME": "https://chromedriver.storage.googleapis.com/LATEST_RELEASE",
    "FIREFOX": "https://github.com/mozilla/geckodriver/releases/latest"
} />

<cfset DriverFolder = getDirectoryFromPath(getCurrentTemplatePath()) & "Drivers/" />

<cfset IsValidBrowser = function(required string name) { return arrayFind(ValidBrowsers, arguments.name) GT 0; } />
<cfset IsValidArchitecture = function(required string name) { return arrayFind(ValidArchitectures, arguments.name) GT 0; } />
<cfset IsValidPlatform = function(required string name) { return arrayFind(ValidPlatforms, arguments.name) GT 0; } />
<!--- Remove all dots and alphabetical characters so we can parse the version as a number, otherwise we can't do a proper number comparison --->
<cfset ParseVersionNumber = function(required string version) { return val(REreplace(arguments.version, "[a-zA-Z|\.]", "", "ALL")); } />
<cfset GetVersionFileName = function(required string browser) { return DriverNames[arguments.browser] & "_version.txt"; } />

<cffunction access="public" name="GetLatestWebdriverBinary" returntype="boolean" output="false" >
    <cfargument name="browser" type="string" required="true" hint="CHROME,FIREFOX" />
    <cfargument name="platform" type="string" required="true" hint="LINUX,WINDOWS" />
    <cfargument name="architecture" type="string" required="true" hint="x86,x64" />
    <cfscript>

        if (!IsValidBrowser(arguments.browser))
            throw(message="Error fetching latest webdriver binary", detail="Argument 'browser' is invalid: #arguments.browser# | Accepted values are: #arrayToList(ValidBrowsers)#");

        if (!IsValidPlatform(arguments.platform))
            throw(message="Error fetching latest webdriver binary", detail="Argument 'platform' is invalid: #arguments.platform# | Accepted values are: #arrayToList(ValidPlatforms)#");

        if (!IsValidArchitecture(arguments.architecture))
            throw(message="Error fetching latest webdriver binary", detail="Argument 'architecture' is invalid: #arguments.architecture# | Accepted values are: #arrayToList(ValidArchitectures)#");

        if (arguments.browser == "CHROME" && arguments.platform == "LINUX" && arguments.architecture == "x86")
            throw(message="Error fetching latest webdriver binary", detail="Chrome on Linux only supports x64");

        var VersionFile = "#DriverFolder#/#GetVersionFileName(arguments.browser)#";
        var CurrentVersion = "0";
        var LatestVersion = DetermineLatestAvailableVersion(arguments.browser);

        if (fileExists(VersionFile))
            CurrentVersion = fileRead(VersionFile);

        if (ParseVersionNumber(CurrentVersion) >= ParseVersionNumber(LatestVersion))
        {
            writeLog(text="WebdriverManager.GetLatestWebdriverBinary: the #arguments.browser#-webdriver is already up to date, not downloading (#CurrentVersion#)", type="information", log="application");
            return true;
        }

        var LatestWebdriverVersionURL = ResolveDownloadURL(LatestVersion, arguments.browser, arguments.platform, arguments.architecture);
        return DownloadAndExtract(arguments.browser, LatestVersion, LatestWebdriverVersionURL);
    </cfscript>
</cffunction>

<cffunction access="public" name="ResolveDownloadURL" returntype="string" output="false" >
    <cfargument name="version" type="string" required="true" hint="" />
    <cfargument name="browser" type="string" required="true" hint="CHROME,FIREFOX" />
    <cfargument name="platform" type="string" required="true" hint="LINUX,WINDOWS" />
    <cfargument name="architecture" type="string" required="false" default="64" hint="x86,x64" />
    <cfscript>

        var PlatformPart = "";
        var ArchitecturePart = "";
        var FileTypePart = "";
        var ReturnData = "";

        switch(arguments.architecture)
        {
            case "x64":
                ArchitecturePart = "64";
                break;
            case "x86":
                ArchitecturePart = "32";
                break;

            default:
                throw(message="Error while resolving download URL", detail="Unsupported architecture: #arguments.architecture#");
        }

        switch(arguments.platform)
        {
            case "LINUX":
                PlatformPart = "linux";
                FileTypePart = "tar.gz";
                break;

            case "WINDOWS":
                PlatformPart = "win";
                FileTypePart = "zip"
                break;

            default:
                throw(message="Error while resolving download URL", detail="Unsupported platform: #arguments.platform#");
        }

        switch(arguments.browser)
        {
            case "FIREFOX":
                ReturnData = "https://github.com/mozilla/geckodriver/releases/download/#arguments.version#/geckodriver-#arguments.version#-#PlatformPart##ArchitecturePart#.#FileTypePart#";
                break;

            case "CHROME":
                ReturnData = "https://chromedriver.storage.googleapis.com/#arguments.version#/chromedriver_#PlatformPart##ArchitecturePart#.zip";
                break;

            default:
                throw(message="Error while resolving download URL", detail="Unsupported browser: #arguments.browser#");
        }

        return ReturnData;
    </cfscript>
</cffunction>

<cffunction access="public" name="DetermineLatestAvailableVersion" returntype="string" output="false" >
    <cfargument name="browser" type="string" required="true" hint="CHROME,FIREFOX" />
    <cfscript>

        if (!IsValidBrowser(arguments.browser))
            throw(message="Unable to determine latest available browser version", detail="Argument 'browser' (#arguments.browser#) is not a valid value (#arrayToList(ValidBrowsers)#)");

        var DoRedirect = (arguments.browser != "FIREFOX");
        var ExpectedStatusCode = (arguments.browser == "FIREFOX" ? 302 : 200)

        var HTTPService = new http(url=#BrowserLatestVersionURLs[arguments.browser]#, method="GET", timeout="10", redirect=#DoRedirect#);
        var LatestVersionResponse = HTTPService.send().getPrefix();

        if (LatestVersionResponse.status_code NEQ ExpectedStatusCode)
        {
            var ErrorMessage = [
                "WebdriverManager.DetermineLatestAvailableVersion: failed to determine latest available webdriver version for #arguments.browser#",
                "URL '#BrowserLatestVersionURLs[arguments.browser]#' returned:",
                "- Status code: #LatestVersionResponse.status_code#",
                "- Status text: #LatestVersionResponse.status_text#",
                "- Error detail: #LatestVersionResponse.errordetail#"
            ];

            writeLog(text=arrayToList(ErrorMessage, chr(13)&chr(10)), type="error", log="Application");
            return "0";
        }

        if (arguments.browser != "FIREFOX")
            return LatestVersionResponse.fileContent;

        // For Firefox we get the redirect URL. Based on that we need to extract the version number from the 'location'-header
        return listLast(LatestVersionResponse.responseheader.location, "/");

    </cfscript>
</cffunction>

<cffunction access="public" name="DownloadAndExtract" returntype="boolean" output="true" >
    <cfargument name="browser" type="string" required="true" hint="" />
    <cfargument name="version" type="string" required="true" hint="" />
    <cfargument name="url" type="string" required="true" hint="" />
    <cfscript>

        var DownloadedFileName = listLast(arguments.url, "/");
        var DownloadedPathAndFile = getTempDirectory() & DownloadedFileName;
        var VersionFileName = GetVersionFileName(arguments.browser);
        var HTTPService = new http(url=#arguments.url#, method="GET", timeout="10", redirect="true");
        var DownloadReponse = HTTPService.send().getPrefix();

        if (DownloadReponse.status_code != 200)
        {
            var ErrorMessage = [
                "WebdriverManager.DownloadAndExtract: failed to download latest available webdriver for #arguments.browser#",
                "URL '#arguments.url#' returned:",
                "- Status code: #DownloadReponse.status_code#",
                "- Status text: #DownloadReponse.status_text#",
                "- Error detail: #DownloadReponse.errordetail#"
            ];

            writeLog(text=arrayToList(ErrorMessage, chr(13)&chr(10)), type="error", log="Application");
            return false;
        }

        // Save the downloaded zip file and extract the contents to the driver-folder
        fileWrite(DownloadedPathAndFile, DownloadReponse.filecontent);
        cfzip(action="unzip", file=#DownloadedPathAndFile#, destination=#DriverFolder#, overwrite="true");

        // (over)Write the version file with the new version and delete the temporary, downloaded zip-file
        fileDelete(DownloadedPathAndFile);
        fileWrite("#DriverFolder#/#VersionFileName#", arguments.version);

        if (IS_UNIX)
        {
            fileSetAccessMode("#DriverFolder#/#WebdriverFileName#", "744");
            fileSetAccessMode("#DriverFolder#/#VersionFileName#", "744");
        }

        return true;
    </cfscript>
</cffunction>

<cfscript>
    // writeDump(arrayFind(["x86"], "x86"));
    // writeDump(IsValidArchitecture("x86"));

    // CHROME - LINUX
    // writeDump(GetLatestWebdriverBinary("CHROME", "LINUX", "x86"));
    // writeDump(GetLatestWebdriverBinary("CHROME", "LINUX", "x64"));

    // CHROME - WINDOWS
    // writeDump(GetLatestWebdriverBinary("CHROME", "WINDOWS", "x86"));
    // writeDump(GetLatestWebdriverBinary("CHROME", "WINDOWS", "x64"));

    // FIREFOX - LINUX
    writeDump(GetLatestWebdriverBinary("FIREFOX", "LINUX", "x86"));
    // writeDump(GetLatestWebdriverBinary("FIREFOX", "LINUX", "x64"));

    // FIREFOX - WINDOWS
    // writeDump(GetLatestWebdriverBinary("FIREFOX", "WINDOWS", "x86"));
    // writeDump(GetLatestWebdriverBinary("FIREFOX", "WINDOWS", "x64"));

</cfscript>

<!--- Extract tar.gz natively: https://gist.github.com/ForeverZer0/a2cd292bd2f3b5e114956c00bb6e872b --->
<!--- MS Edge manifest (XML): https://msedgedriver.azureedge.net/ --->
<!--- MS Edge latest stable: https://msedgewebdriverstorage.blob.core.windows.net/edgewebdriver/LATEST_STABLE --->