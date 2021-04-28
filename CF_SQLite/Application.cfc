<cfcomponent output="false">

	<cfset this.name="SQLiteTest" />
	<cfset this.applicationtimeout = createTimeSpan(1,0,0,0) />
	<cfset this.setClientCookies = false />

	<cfset this.root = getDirectoryFromPath(getCurrentTemplatePath()) />

	<cfset this.defaultdatasource = {
        class: "org.sqlite.JDBC",
        connectionString: "jdbc:sqlite:#this.root#\test.sdb",
        timezone: "CET",
        custom: {useUnicode: true, characterEncoding: 'UTF-8', Version: 3},
        blob: true,
        clob: true,
        validate: true
    } />

	<cffunction name="onApplicationStart" returntype="boolean" output="false" >

		<!--- <cfset var DbLibFile = "#this.root#\sqlite-jdbc-3.30.1.jar" /> <!--- https://bitbucket.org/xerial/sqlite-jdbc/downloads/ --->

		<cfset var CFMLEngine = createObject( "java", "lucee.loader.engine.CFMLEngineFactory" ).getInstance() />
		<cfset var OSGiUtil = createObject( "java", "lucee.runtime.osgi.OSGiUtil" ) />
		<cfset var resource = CFMLEngine.getResourceUtil().toResourceExisting( getPageContext(), DbLibFile ) />

		<cfset OSGiUtil.installBundle(
			CFMLEngine.getBundleContext(),
			resource,
			true
		) /> --->

		<cfreturn true />
	</cffunction>

</cfcomponent>