<cfcomponent output="false" >

	<cfset this.name="CF_MVC" />
	<cfset this.applicationtimeout = CreateTimeSpan(14,0,0,0) />
	<cfset this.sessionmanagement = true />
	<cfset this.sessiontimeout = CreateTimeSpan(0,0,35,0) />
	<cfset this.loginstorage = "session" />
	<cfset this.setClientCookies = true />
	<!--- <cfset this.scriptProtect = "all" /> --->

	<!--- MAPPINGS --->
	<cfset this.root = getDirectoryFromPath(getCurrentTemplatePath()) />
	<cfset this.mappings["/MVC"] = "#this.root#MVC/" />
	<cfset this.mappings["/Views"] = "#this.root#views/" />
	<cfset this.mappings["/Models"] = "#this.root#models/" />
	<cfset this.mappings["/Controllers"] = "#this.root#controllers/" />

	<cffunction name="onApplicationStart" returnType="boolean" output="false" >
		<!--- <cfset application.rootDir = this.root /> --->

		<cfset application.MVC = new MVC.MVC(expandPath("/Controllers"), this.root, nullValue()) />

		<cfreturn true />
	</cffunction>

    <cffunction name="onRequest" returntype="void" output="true" >
        <cfargument type="string" name="targetPage" required="true" />

        <cfscript>
		if (listLast(arguments.targetPage, "/") NEQ "index.cfm")
		{
			cfheader(statuscode="404");
			return;
		};
		var Context = new MVC.RequestContext(getHTTPRequestData().headers, FORM, URL);
		var Response = application.MVC.ResolveRequest(Context);

		cfheader(statuscode=Response.GetStatusCode());
		// cfcontent(reset="true", type=Response.GetContentType());
        writeOutput(Response.GetBody());

		if (structKeyExists(URL, "Debug"))
		{
			writeOutput("<hr/>");
			writeDump(Response);
		}
		</cfscript>
    </cffunction>

    <cffunction name="onRequestEnd" returntype="void" output="false" >
        <cfargument type="string" name="targetPage" required=true />

		<!--- <cfdump var=#arguments.targetPage# /> --->
    </cffunction>

	<cffunction name="onRequestStart" returnType="boolean" output="true" >
		<cfargument type="string" name="targetPage" required=true />

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
			<cflocation url="http://#CGI.SERVER_NAME#/Sandbox/CF_MVC/index.cfm" addtoken="false" statuscode="301" />

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