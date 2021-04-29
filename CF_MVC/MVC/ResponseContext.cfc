<cfcomponent persistent="true" accessors="false" output="false" modifier="final" >

    <cfproperty name="Headers"         type="struct"         getter="true" setter="false" />
    <cfproperty name="StatusCode"      type="numeric"        getter="true" setter="true" default="200" />
    <cfproperty name="Body"            type="string"         getter="true" setter="true" default="" />
    <cfproperty name="ContentType"     type="string"         getter="true" setter="true" default="text/html; charset=utf-8" />

    <cffunction access="public" name="init" returntype="ResponseContext" output="false" >
        <cfset variables.Headers = {} />
        <cfreturn this />
    </cffunction>

</cfcomponent>