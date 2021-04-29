<cfcomponent persistent="true" accessors="false" output="false" modifier="final" >

    <cfproperty name="ServiceList" type="struct" getter="false" setter="false" />

    <cffunction access="public" name="init" returntype="ServiceLocator" output="false" >
        <cfreturn this />
    </cffunction>

    <cffunction access="public" name="Provide" returntype="void" output="false" >
        <cfargument name="name" type="string" required="true" />
        <cfargument name="service" type="any" required="true" />
        <cfscript>

        if (isObject(arguments.service))
        {
            variables.ServiceList[arguments.name] = arguments.service;
            return;
        }

        throw(message="Error adding service to locator", detail="Argument 'service' is not an object");
        </cfscript>
    </cffunction>

    <cffunction access="public" name="Get" returntype="any" output="false" >
        <cfargument name="name" type="string" required="true" />
        <cfscript>

        if (structKeyExists(variables.ServiceList, arguments.name))
            return variables.ServiceList[arguments.name];

        return nullValue();
        </cfscript>
    </cffunction>
</cfcomponent>