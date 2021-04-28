<cfcomponent output="false">

	<cfset this.name="CF_MVC" />
	<cfset this.applicationtimeout = CreateTimeSpan(14,0,0,0) />
	<cfset this.sessionmanagement = true />
	<cfset this.sessiontimeout = CreateTimeSpan(0,0,35,0) />
	<cfset this.loginstorage = "session" />
	<cfset this.setClientCookies = true />
	<cfset this.scriptProtect = "all" />

	<!--- MAPPINGS --->

	<cfset this.root = getDirectoryFromPath( getCurrentTemplatePath() ) />

	<cffunction name="onApplicationStart" returnType="boolean" output="false">
		<cfset application.rootDir = this.root />

		<cfreturn true />
	</cffunction>

    <cffunction name="onRequest" returntype="void" output="true" >
        <cfargument type="string" name="targetPage" required=true />
        <cfscript>

        <!--- <cfdump var="onRequest: #arguments.targetPage#" /> --->
        if (!structKeyExists(URL, "action")) return;

        var Actions = listToArray(URL.action, ".", false);
        var Controller = Actions[1];
        var Method = Actions.len() GT 1 ? Actions[2] : "default";
        structDelete(URL, "action");

        <!--- <cfdump var=#getComponentMetadata("controllers.#controller#").functions# /> --->
        var RequestContext = {
            URL: URL,
            FORM: FORM,
            Output: "",
            ContentType: "text/plain"
        };

        invoke("controllers.#controller#", method, {context: RequestContext});
        </cfscript>

        <cfheader name="Content-Type" value=#RequestContext.ContentType# />
        <cfoutput>#RequestContext.Output#</cfoutput>
    </cffunction>

    <cffunction name="onRequestEnd" returntype="void" output="true" >
        <cfargument type="string" name="targetPage" required=true />

    </cffunction>

	<cffunction name="onRequestStart" returnType="boolean" output="true" >
		<cfargument type="string" name="targetPage" required=true />

        <!--- <cfdump var="onRequestStart: #arguments.targetPage#" /> --->

		<!--- For force refreshing static content programmatically, rather than using Shift + F5 or similar means --->
		<cfif structKeyExists(URL, "Refresh") >
			<cfheader name="Cache-Control" value="no-cache, no-store, must-revalidate" />
			<cfheader name="Pragma" value="no-cache" />
			<cfheader name="Expires" value="0" />
		</cfif>

		<!--- For testing purposes, this nukes the session and restarts the application --->
		<cfif structKeyExists(URL, "Restart") >

			<cfset sessionInvalidate() />
			<cfset applicationStop() />
			<cflocation url="http://#CGI.SERVER_NAME#/Debug/index.cfm" addtoken="false" />

		</cfif>

		<cfreturn true />
	</cffunction>

	<cffunction name="onSessionEnd" returntype="void" output="false">
		<cfargument name="SessionScope" required=true />
		<cfargument name="ApplicationScope" required=false />

		<cfcookie name="CFID" value="" expires="Thu, 01 Jan 1970 00:00:00 GMT" />
		<cfcookie name="CFTOKEN" value="" expires="Thu, 01 Jan 1970 00:00:00 GMT" />
		<cfset structClear(arguments.SessionScope) />
	</cffunction>

</cfcomponent>