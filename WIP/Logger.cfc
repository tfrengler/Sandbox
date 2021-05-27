<cfcomponent modifier="final" persistent="true" output="false" accessors="false" implements="ILogger" >

    <cffunction access="public" name="Information" returntype="void" output="true" >
        <cfargument name="data" type="any" required="true" />
        <cfargument name="calledBy" type="string" required="false" default="UNKNOWN" />

        <cfdump var=#arguments.data# />
    </cffunction>

    <cffunction access="public" name="Warning" returntype="void" output="true" >
        <cfargument name="data" type="any" required="true" />
        <cfargument name="calledBy" type="string" required="false" default="UNKNOWN" />

        <cfdump var=#arguments.data# />
    </cffunction>

    <cffunction access="public" name="Error" returntype="void" output="true" >
        <cfargument name="data" type="any" required="true" />
        <cfargument name="calledBy" type="string" required="false" default="UNKNOWN" />

        <cfdump var=#arguments.data# />
    </cffunction>
</cfcomponent>