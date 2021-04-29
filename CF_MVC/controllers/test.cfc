<cfcomponent persistent="true" accessors="false" output="false" extends="MVC.BaseController" >

    <cffunction access="public" name="main" returntype="void" >
        <cfargument name="context" type="RequestContext" required="true" >
        <cfargument name="response" type="MVC.ResponseContext" required="true" />
        <cfscript>

        var Output = "";
        cfsavecontent(variable="Output", trim=true)
        {
            cfmodule(template="/Views/test/howdy.cfm", context=arguments.context);
        }

        arguments.response.SetBody(Output);
        </cfscript>
    </cffunction>
</cfcomponent>