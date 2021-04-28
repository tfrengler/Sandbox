<cfcomponent persistent="true" output="false" implements="IController" >

    <cffunction access="public" name="howdy" returntype="struct" >
        <cfargument name="context" type="struct" required="true" >
        <cfscript>

        cfcontent(reset=true);
        cfsavecontent(variable="arguments.context.output", trim=true)
        {
            cfmodule(template="..\views\test\howdy.cfm" context=arguments.context);
        }

        arguments.context.ContentType = "text/html";
        return arguments.context;
        </cfscript>
    </cffunction>

    <cffunction access="public" name="default" returntype="void" >
        <cfargument name="context" type="struct" required="true" >

        <cfreturn arguments.context />
    </cffunction>

</cfcomponent>