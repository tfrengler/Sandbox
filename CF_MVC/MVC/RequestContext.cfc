<cfcomponent persistent="true" accessors="false" output="false" modifier="final" >

    <cfproperty name="Controller"   type="string"   getter="true" setter="true" />
    <cfproperty name="Item"         type="string"   getter="true" setter="true" />

    <cfproperty name="Headers"      type="struct"   getter="true" setter="false" />
    <cfproperty name="FORM"         type="struct"   getter="true" setter="false" />
    <cfproperty name="URL"          type="struct"   getter="true" setter="false" />

    <cfproperty name="RenderView"   type="Function"   getter="true" setter="true" />
    <cfproperty name="RenderModule" type="Function"   getter="true" setter="true" />


    <cffunction access="public" name="init" returntype="RequestContext" output="false" >
        <cfargument name="headers" type="struct" required="true" />
        <cfargument name="form" type="struct" required="true" />
        <cfargument name="url" type="struct" required="true" />

        <cfset variables.Headers = arguments.headers />
        <cfset variables.FORM = arguments.form />
        <cfset variables.URL = arguments.url />

        <cfreturn this />
    </cffunction>

</cfcomponent>