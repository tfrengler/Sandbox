<cfcomponent output="false">

	<cfset this.name="SimpleMailTest" />
	<cfset this.applicationtimeout = createTimeSpan(1,0,0,0) />
	<cfset this.sessiontimeout = createTimespan(0, 1, 0, 0) />
	<cfset this.sessionmanagement = true />
	<cfset this.setClientCookies = true />
	<!--- <cfset this.javaSettings.loadPaths = "./jars" /> --->

	<cffunction name="onApplicationStart" returnType="boolean" output="false" >

		<cfset var qJarFiles = "" />
		<cfdirectory directory="./Jars" name="qJarFiles" type="file" filter="*.jar" />
		<cfset var aJarDependencies = [] />

		<cfloop query=#qJarFiles# >
			<cfset arrayAppend(aJarDependencies, "#qJarFiles.directory#\#qJarFiles.name#") />
		</cfloop>

		<cfset application.oJavaloader = createObject("component", "javaloader.JavaLoader").init(aJarDependencies, false) />

		<cfreturn true />
	</cffunction>

	<cffunction name="onRequestStart" returntype="boolean" output="false" >
		<cfargument type="string" name="targetPage" required="true" />

		<!--- For testing purposes, this nukes the session and restarts the application --->
		<cfif structKeyExists(URL, "Restart") >
			<cfset sessionInvalidate() />
			<cfset applicationStop() />
			<cflocation url=#CGI.SCRIPT_NAME# addtoken="false" />
		</cfif>

		<cfreturn true />
	</cffunction>

</cfcomponent>