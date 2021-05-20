<cfset OS = createObject("java", "java.lang.System").getProperty("os.name").toLowerCase() />
<cfset IS_WINDOWS = (find("win", OS) GT 0) />
<cfset IS_MAC = (find("mac", OS) GT 0) />
<cfset IS_UNIX = (find("nix", OS) GT 0 OR find("nux", OS) GT 0 OR find("aix", OS) GT 0) />

<cfset ValidBrowsers = ["CHROME","FIREFOX", "EDGE"] />
<cfset ValidArchitectures = ["x64","x86"] />
<cfset ValidPlatforms = ["WINDOWS","LINUX"] />

<cfset DriverNames = {
    "FIREFOX": "geckodriver",
    "CHROME": "chromedriver",
    "EDGE": "msedgedriver"
} />

<cfset BrowserLatestVersionURLs = {
    "CHROME": "https://chromedriver.storage.googleapis.com/LATEST_RELEASE",
    "FIREFOX": "https://github.com/mozilla/geckodriver/releases/latest",
    "EDGE": "https://msedgewebdriverstorage.blob.core.windows.net/edgewebdriver/LATEST_STABLE"
} />

<cfset DriverFolder = getDirectoryFromPath(getCurrentTemplatePath()) & "Drivers/" />

<cfset IsValidBrowser = function(required string name) { return arrayFind(ValidBrowsers, arguments.name) GT 0; } />
<cfset IsValidArchitecture = function(required string name) { return arrayFind(ValidArchitectures, arguments.name) GT 0; } />
<cfset IsValidPlatform = function(required string name) { return arrayFind(ValidPlatforms, arguments.name) GT 0; } />
<!--- Remove all dots and alphabetical characters so we can parse the version as a number, otherwise we can't do a proper number comparison --->
<cfset ParseVersionNumber = function(required string version) { return val(REreplace(arguments.version, "[a-zA-Z|\.]", "", "ALL")); } />
<cfset GetVersionFileName = function(required string browser, required string platform) { return "#DriverNames[arguments.browser]#_#arguments.platform#_version.txt"; } />

<!--- PUBLIC --->
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

        if (arguments.browser == "EDGE" && arguments.platform == "LINUX")
            throw(message="Error fetching latest webdriver binary", detail="Edge is not available on Linux");

        if (arguments.browser == "CHROME" && arguments.platform == "LINUX" && arguments.architecture == "x86")
            throw(message="Error fetching latest webdriver binary", detail="Chrome on Linux only supports x64");

        var VersionFile = "#DriverFolder#/#GetVersionFileName(arguments.browser, arguments.platform)#";
        var CurrentVersion = "0";
        var LatestVersion = DetermineLatestAvailableVersion(arguments.browser);

        if (fileExists(VersionFile))
            CurrentVersion = fileRead(VersionFile);

        if (ParseVersionNumber(CurrentVersion) >= ParseVersionNumber(LatestVersion))
        {
            writeLog(text="WebdriverManager.GetLatestWebdriverBinary: the #arguments.browser#-webdriver is already up to date, not downloading (#CurrentVersion#)", type="Information", log="Application");
            return true;
        }

        var LatestWebdriverVersionURL = ResolveDownloadURL(LatestVersion, arguments.browser, arguments.platform, arguments.architecture);
        return DownloadAndExtract(arguments.browser, arguments.platform, LatestVersion, LatestWebdriverVersionURL);
    </cfscript>
</cffunction>

<cffunction access="public" name="DetermineLatestAvailableVersion" returntype="string" output="false" >
    <cfargument name="browser" type="string" required="true" hint="CHROME,FIREFOX" />
    <cfscript>

        if (!IsValidBrowser(arguments.browser))
            throw(message="Unable to determine latest available browser version", detail="Argument 'browser' (#arguments.browser#) is not a valid value (#arrayToList(ValidBrowsers)#)");

        var ExpectedStatusCode = (arguments.browser == "FIREFOX" ? 302 : 200);
        var AllowRedirect = arguments.browser != "FIREFOX";

        var HTTPService = new http(url=#BrowserLatestVersionURLs[arguments.browser]#, method="GET", timeout="10", redirect=#AllowRedirect#);
        var LatestVersionResponse = HTTPService.send().getPrefix();

        if (LatestVersionResponse.status_code != ExpectedStatusCode)
        {
            var ErrorMessage = [
                "WebdriverManager.DetermineLatestAvailableVersion: failed to determine latest available webdriver version for #arguments.browser#",
                "URL '#BrowserLatestVersionURLs[arguments.browser]#' returned:",
                "- Status code: #LatestVersionResponse.status_code#",
                "- Status text: #LatestVersionResponse.status_text#",
                "- Error detail: #LatestVersionResponse.errordetail#"
            ];

            writeLog(text=arrayToList(ErrorMessage, "#chr(13)&chr(10)#"), type="error", log="Application");
            return "0";
        }

        if (arguments.browser != "FIREFOX")
            return trim(LatestVersionResponse.fileContent);

        // For Firefox we get the redirect URL. Based on that we need to extract the version number from the 'location'-header
        return listLast(LatestVersionResponse.responseheader.location, "/");
    </cfscript>
</cffunction>

<!--- PRIVATE --->
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

            case "EDGE":
                ReturnData = "https://msedgewebdriverstorage.blob.core.windows.net/edgewebdriver/#arguments.version#/edgedriver_#PlatformPart##ArchitecturePart#.zip";
                break;

            default:
                throw(message="Error resolving webdriver download URL", detail="Unsupported browser: #arguments.browser#");
        }

        return ReturnData;
    </cfscript>
</cffunction>

<cffunction access="public" name="DownloadAndExtract" returntype="boolean" output="false" >
    <cfargument name="browser" type="string" required="true" hint="" />
    <cfargument name="platform" type="string" required="true" hint="" />
    <cfargument name="version" type="string" required="true" hint="" />
    <cfargument name="url" type="string" required="true" hint="" />
    <cfscript>

        var DownloadedFileName = listLast(arguments.url, "/");
        var DownloadedPathAndFile = getTempDirectory() & DownloadedFileName;
        var VersionFileName = GetVersionFileName(arguments.browser, arguments.platform);
        var WebdriverFileName = DriverNames[arguments.browser];
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

            writeLog(text=arrayToList(ErrorMessage, "#chr(13)&chr(10)#"), type="Error", log="Application");
            return false;
        }

        if (arguments.browser == "FIREFOX" && arguments.platform == "LINUX")
        {
            var ExtractedTarFileName = DownloadedFileName.replace(".gz", "");
            if (!ExtractTarGz(DownloadReponse.fileContent, ExtractedTarFileName)) return false;
            if (!ExtractTar(ExtractedTarFileName)) return false;

            // Re-assigning the variable since we don't download the original file to disk
            // This is now the extracted tar-file, and not the tar.gz one
            DownloadedPathAndFile = getTempDirectory() & ExtractedTarFileName;
        }
        else
        {
            // Save the downloaded zip file and extract the contents to the driver-folder
            fileWrite(DownloadedPathAndFile, DownloadReponse.filecontent);
            cfzip(action="unzip", file=#DownloadedPathAndFile#, destination=#DriverFolder#, overwrite="true");
        }

        // (over)Write the version file with the new version and delete the temporary, downloaded zip-file
        fileWrite("#DriverFolder#/#VersionFileName#", arguments.version);

        if (IS_UNIX)
        {
            fileSetAccessMode("#DriverFolder#/#WebdriverFileName#", "744");
            fileSetAccessMode("#DriverFolder#/#VersionFileName#", "744");
        }

        // Clean-up, removing the zip-file...
        fileDelete(DownloadedPathAndFile);
        // ...and of course the Edge-zip contains a silly, extra folder and not just the driver binary...
        if (arguments.browser == "EDGE" && directoryExists("#DriverFolder#/Driver_Notes"))
            directoryDelete("#DriverFolder#/Driver_Notes", true);

        return true;
    </cfscript>
</cffunction>

<cffunction access="public" name="ExtractTarGz" returntype="boolean" output="false" >
    <cfargument name="tarAsByteArray" type="binary" required="true" hint="" />
    <cfargument name="outputFileName" type="string" required="true" hint="" />
    <cfscript>
        try
        {
            var InputStream = createObject("java", "java.io.ByteArrayInputStream").init(arguments.tarAsByteArray);
            var GZIPInputStream = createObject("java", "java.util.zip.GZIPInputStream").init(InputStream);
            var OutputStream = createObject("java", "java.io.FileOutputStream").init(getTempDirectory() & arguments.outputFileName);

            var EmptyByteArray = createObject("java", "java.io.ByteArrayOutputStream").init().toByteArray();
            var Buffer = createObject("java","java.lang.reflect.Array").newInstance(EmptyByteArray.getClass().getComponentType(), 1024);
            var Length = GZIPInputStream.read(Buffer);

            while(Length != -1)
            {
                OutputStream.write(Buffer, 0, Length);
                Length = GZIPInputStream.read(Buffer);
            }

            return true;
        }
        catch(any error)
        {
            var ErrorMessage = [
                "WebdriverManager.ExtractTarGz: failed to extract tar-file from byte array to output file (#getTempDirectory() & arguments.outputFileName#):",
                "- Message: #error.message#",
                "- Stacktrace: #error.stacktrace#"
            ];

            writeLog(text=arrayToList(ErrorMessage, "#chr(13)&chr(10)#"), type="Error", log="Application");
            return false;
        }
        finally
        {
            if (isDefined("OutputStream")) OutputStream.close();
            if (isDefined("GZIPInputStream")) GZIPInputStream.close();
        }
    </cfscript>
</cffunction>

<!--- NOTE: This is a NOT a complete implementation of tar-extraction. It only extracts the first item and it assumes it's a file --->
<!--- It's purely written for the purpose of extracting webdriver binaries on Linux!--->
<cffunction name="ExtractTar" access="public" returntype="boolean" output="false" >
    <cfargument name="tarFileName" type="string" required="true" />
    <cfscript>
        try
        {
            // Set up the input file as a stream, and prepare the input buffer
            var File = createObject("java", "java.io.File").init(getTempDirectory() & arguments.tarFileName);
            var InputStream = createObject("java", "java.io.FileInputStream").init(File);
            var EmptyByteArray = createObject("java", "java.io.ByteArrayOutputStream").init().toByteArray();
            var InputBuffer = createObject("java","java.lang.reflect.Array").newInstance(EmptyByteArray.getClass().getComponentType(), 100);

            // Read in a 100 bytes, parse it as an ASCII string and discard (remove) all null characters from the string
            // This should give us the file name
            InputStream.read(InputBuffer, 0, 100);
            var Name = createObject("java", "java.lang.String").init(InputBuffer, "US-ASCII");
            Name = REreplace(Name, "[\x0]", "", "ALL");

            // Seek ahead 24 bytes in the stream and read out 12 bytes. Time to find the file size
            InputStream.skip(24);
            InputStream.read(InputBuffer, 0, 12);

            // Pull out the 12 bytes of our buffer we just read in, and parse it as a UTF-8 string
            // Replace all null characters, then parse it as a raw number
            // Lastly, parse as an unsigned 64-bit character using an octal radix
            var ByteSubset = createObject("java", "java.util.Arrays").copyOfRange(InputBuffer, 0, 12);
            var SizeAsString = createObject("java", "java.lang.String").init(ByteSubset, "UTF-8");
            SizeAsString = REreplace(SizeAsString, "[\x0]", "", "ALL");
            var FinalSize = createObject("java", "java.lang.Long").parseUnsignedLong(val(SizeAsString), 8);

            InputStream.skip(376);

            // Create our output file and output buffer, then read out the amount of bytes equal to our file size and write that to the output file
            var OutputPathAndFileName = "#DriverFolder#/#Name#";
            var OutputStream = createObject("java", "java.io.FileOutputStream").init(OutputPathAndFileName);
            var OutputBuffer = createObject("java","java.lang.reflect.Array").newInstance(EmptyByteArray.getClass().getComponentType(), FinalSize);

            InputStream.read(OutputBuffer, 0, FinalSize);
            OutputStream.write(OutputBuffer);

            return true;
        }
        catch(any error)
        {
            var ErrorMessage = [
                "WebdriverManager.ExtractTar: failed to extract tar-file from tar.gz-file (#getTempDirectory() & arguments.tarFileName#):",
                "- Message: #error.message#",
                "- Stacktrace: #error.stacktrace#"
            ];

            writeLog(text=arrayToList(ErrorMessage, "#chr(13)&chr(10)#"), type="Error", log="Application");
            return false;
        }
        finally
        {
            if (isDefined("InputStream")) InputStream.close();
            if (isDefined("OutputStream")) OutputStream.close();
        }
    </cfscript>
</cffunction>

<cfscript>
    // CHROME - LINUX
    // writeDump(var=GetLatestWebdriverBinary("CHROME", "LINUX", "x86"), label="CHROME LINUX x86"); // Expecting an error
    // writeDump(var=GetLatestWebdriverBinary("CHROME", "LINUX", "x64"), label="CHROME LINUX x64");

    // CHROME - WINDOWS
    // writeDump(var=GetLatestWebdriverBinary("CHROME", "WINDOWS", "x86"), label="CHROME WINDOWS x86");
    // writeDump(var=GetLatestWebdriverBinary("CHROME", "WINDOWS", "x64"), label="CHROME WINDOWS x64");

    // FIREFOX - LINUX
    // writeDump(GetLatestWebdriverBinary("FIREFOX", "LINUX", "x86"));
    // writeDump(GetLatestWebdriverBinary("FIREFOX", "LINUX", "x64"));

    // FIREFOX - WINDOWS
    // writeDump(GetLatestWebdriverBinary("FIREFOX", "WINDOWS", "x86"));
    // writeDump(GetLatestWebdriverBinary("FIREFOX", "WINDOWS", "x64"));

    // EDGE - WINDOWS
    // writeDump(GetLatestWebdriverBinary("EDGE", "WINDOWS", "x86"));
    // writeDump(GetLatestWebdriverBinary("EDGE", "WINDOWS", "x64"));
</cfscript>

<!--- Extract tar.gz natively: https://gist.github.com/ForeverZer0/a2cd292bd2f3b5e114956c00bb6e872b --->
<!--- MS Edge manifest (XML): https://msedgedriver.azureedge.net/ --->
<!--- MS Edge latest stable: https://msedgewebdriverstorage.blob.core.windows.net/edgewebdriver/LATEST_STABLE --->