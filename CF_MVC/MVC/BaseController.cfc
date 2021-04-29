<cfcomponent persistent="true" accessors="false" output="false" modifier="abstract" >

    <cfproperty name="Services" type="ServiceLocator" getter="false" setter="false" />

    <cffunction modifier="final" access="public" name="init" returntype="BaseController" output="false" >
        <cfargument name="services" type="ServiceLocator" required="true" >
        <cfset variables.Services = arguments.services />

        <cfreturn this />
    </cffunction>

    <cffunction modifier="final" access="public" name="default" returntype="void" output="false" >
        <cfargument name="context" type="MVC.RequestContext" required="true" />
        <cfargument name="response" type="MVC.ResponseContext" required="true" />

        <cfscript>
        var Output = "";
        cfsavecontent(variable="Output", trim=true)
        {
            cfmodule(template="/Views/#arguments.context.GetController()#/default.cfm", context=arguments.context);
        }

        arguments.response.SetBody(Output);
        </cfscript>
    </cffunction>

</cfcomponent>