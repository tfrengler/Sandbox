<cfcomponent output="false" >

    <cfset this.name = "CfWebSocket" />
    <cfset this.applicationtimeout = CreateTimeSpan(1,0,0,0) />

    <cfset this.sessionmanagement = true />
    <cfset this.setClientCookies = true />
    <cfset this.sessioncookie.secure = true />
    <cfset this.sessiontimeout = CreateTimeSpan(0,1,0,0) />
    <cfset this.sessionType = "cfml" />
    <cfset this.loginstorage = "session" />

    <cfset this.scriptProtect = "all" />
    <cfset this.invokeImplicitAccessor = false />

    <cfset this.appRoot = getDirectoryFromPath(getCurrentTemplatePath()) />
    <cfset this.mappings = {} />

    <cffunction name="onRequestStart" returntype="boolean" output="false" >
        <cfargument type="string" name="targetPage" required="true" />
        <cfscript>
            if (structKeyExists(URL, "Nuke")) {
                applicationStop();
                cflocation(addtoken="false", url=#arguments.targetPage#);
            }

            return true;
        </cfscript>
    </cffunction>

    <cffunction name="onMissingTemplate" returnType="void" output="true" >
        <cfargument type="string" name="targetPage" required="true" />

        <cfscript>
            writeDump("Missing template: #arguments.targetPage#");
        </cfscript>
    </cffunction>

    <cffunction name="onSessionEnd" returntype="void" output="false">
        <cfargument name="sessionScope" type="struct" required="true" />
        <cfargument name="applicationScope" type="struct" required="true" />

        <cfset sessionInvalidate() />
    </cffunction>

</cfcomponent>