<cfcomponent output="false" modifier="final" accessors="false" implements="ILogger" >

    <!--- PROPERTIES --->

    <cfset variables.availableCharsets = ["utf-8","iso-8859-1","windows-1252","us-ascii","shift_jis","iso-2022-jp","euc-jp","euc-kr","big5","euc-cn","utf-16"] />
    <cfset variables.validLogTypes = ["txt", "html"] />

    <cfset variables.absolutePathToLogFolder = nullValue() />
    <cfset variables.charset = nullValue() />
    <cfset variables.logType = nullValue() />

    <!--- PUBLIC --->

    <cffunction name="init" returntype="LogManager" access="public" output="false" >
        <cfargument name="absolutePathToLogFolder" type="string" required="true" />
        <cfargument name="type" type="string" required="true" />
        <cfargument name="charset" type="string" required="false" default="UTF-8" />

        <cfif arrayFindNoCase(variables.validLogTypes, arguments.type) IS 0 >
            <cfthrow message="Error initializing LogManager" detail="Argument 'type' is not valid: #arguments.type# | Valid types are: #arrayToList(variables.availableCharsets)#" />
        </cfif>

        <cfif arrayFindNoCase(variables.availableCharsets, arguments.charset) IS 0 >
            <cfthrow message="Error initializing LogManager" detail="The charset is not supported: #arguments.charset# | Supported charsets are: #arrayToList(variables.availableCharsets)#" />
        </cfif>

        <cfif NOT directoryExists(arguments.absolutePathToLogFolder) >
            <cfthrow message="Error initializing LogManager" detail="The folder from argument 'absolutePathToLogFolder' does not exist (#arguments.absolutePathToLogFolder#)" />
        </cfif>

        <cfset variables.absolutePathToLogFolder = arguments.absolutePathToLogFolder />
        <cfset variables.charset = arguments.charset />
        <cfset variables.logType = lCase(arguments.type) />

        <cfreturn this />
    </cffunction>

    <cffunction access="public" name="Information" returntype="void" output="false" >
        <cfargument name="data" type="any" required="true" />
        <cfargument name="calledBy" type="string" required="false" default="UNKNOWN" />

        <cfset variables.log(data, "INFO", arguments.calledBy) />
    </cffunction>

    <cffunction access="public" name="Warning" returntype="void" output="false" >
        <cfargument name="data" type="any" required="true" />
        <cfargument name="calledBy" type="string" required="false" default="UNKNOWN" />

        <cfset variables.log(data, "WARNING", arguments.calledBy) />
    </cffunction>

    <cffunction access="public" name="Error" returntype="void" output="false" >
        <cfargument name="data" type="any" required="true" />
        <cfargument name="calledBy" type="string" required="false" default="UNKNOWN" />

        <cfset variables.log(data, "ERROR", arguments.calledBy) />
    </cffunction>

    <!--- PRIVATE --->

    <cffunction access="public" name="log" returntype="void" output="false" >
        <cfargument name="data" type="any" required="true" />
        <cfargument name="type" type="string" required="true" />
        <cfargument name="calledBy" type="string" required="false" default="UNKNOWN" />

        <cfif isSimpleValue(arguments.data) >
            <cfset logSimple(arguments.data, arguments.type, arguments.calledBy) />
            <cfreturn/>
        </cfif>

        <!--- Complex data types are dumped and logged as HTML --->
        <cfset logComplex(arguments.data, arguments.type, arguments.calledBy) />
    </cffunction>

    <cffunction access="private" name="logSimple" returntype="void" output="false" >
        <cfargument name="data" type="any" required="true" />
        <cfargument name="type" type="string" required="false" default="INFO" />
        <cfargument name="calledBy" type="string" required="false" default="UNKNOWN" />

        <cfset writeToDisk(
            generateLogEntry(trim(arguments.data), arguments.type, arguments.calledBy),
            variables.logType
        ) />
    </cffunction>

    <cffunction access="private" name="logComplex" returntype="void" output="false" >
        <cfargument name="data" type="any" required="true" />
        <cfargument name="type" type="string" required="false" default="INFO" />
        <cfargument name="calledBy" type="string" required="false" default="UNKNOWN" />

        <cfset var logEntry = "" />

        <cfsavecontent variable="logEntry" >
        <cfoutput>

        <section class="logEntry" >
            <h1 style="#trim(getHTMLStylingForLogType(type=arguments.type))#" >#trim(getOutputPrependData(calledBy=arguments.calledBy, eventCode=arguments.eventCode))#:</h1>
            <p>
                <cfdump var=#arguments.data# />
            </p>
        </section>
        <hr/>

        </cfoutput>
        </cfsavecontent>

        <cfset logEntry = reReplace(logEntry, "<script[\s\S\n]+?/script>", "", "ALL") />
        <!--- <cfset arguments.data = reReplace(arguments.data, " +", " ", "ALL") /> --->

        <cfset writeToDisk(logEntry=trim(logEntry), fileExtension="html") />
    </cffunction>

    <cffunction access="private" name="writeToDisk" returntype="void" output="false">
        <cfargument name="logEntry" type="string" required="true" />
        <cfargument name="fileExtension" type="string" required="false" default="txt" />

        <cfset var fullFilePathAndName = variables.absolutePathToLogFolder & getLogFileName() & "." & arguments.fileExtension />

        <cfif fileExists(fullFilePathAndName) >
            <cffile action="append" output=#arguments.logEntry# file=#fullFilePathAndName# charset=#variables.charset# addnewline="true" />
            <cfreturn/>
        </cfif>

        <cffile action="write" output=#arguments.logEntry# file=#fullFilePathAndName# charset=#variables.charset# addnewline="true" />
        <cfset fileSetAccessMode(fullFilePathAndName, "204") />
    </cffunction>

    <cffunction access="private" name="getLogFileName" returntype="string" output="false">
        <cfset var logFileName = "EventLog_" & lsDateFormat(now(), "yyyy_mm_dd") />
        <cfreturn logFileName />
    </cffunction>

    <cffunction access="private" name="getHTMLStylingForLogType" returntype="string" output="false">
        <cfargument name="type" type="string" required="false" default="INFO" />

        <cfset var HTMLStyleString = nullValue() />

        <cfswitch expression=#arguments.type# >
            <cfcase value="WARNING" >
                <cfset HTMLStyleString = "background-color: orange; color: white;" />
            </cfcase>

            <cfcase value="CRITICAL" >
                <cfset HTMLStyleString = "background-color: red; color: white;" />
            </cfcase>

            <cfdefaultcase>
                <cfset HTMLStyleString = "background-color: green; color: white;" />
            </cfdefaultcase>
        </cfswitch>

        <cfreturn HTMLStyleString />
    </cffunction>

    <cffunction access="private" name="generateLogEntry" returntype="string" output="false">
        <cfargument name="data" type="string" required="true" />
        <cfargument name="type" type="string" required="true" />
        <cfargument name="calledBy" type="string" required="true" />

        <cfset var ReturnData = "#LSDateTimeFormat(now(), "[dd/mm/yyyy - HH:nn:ss]")# - [#arguments.calledBy#] - [#arguments.type#]: #arguments.data#" />
        <cfif variables.logType IS "html" >
            <cfset ReturnData = "<p style='#getHTMLStylingForLogType(arguments.type)#''>#ReturnData#</p>" />
        </cfif>

        <cfreturn ReturnData />
    </cffunction>
</cfcomponent>