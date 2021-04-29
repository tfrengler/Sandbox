<cfcomponent persistent="true" accessors="false" output="false" modifier="final" >

    <cfproperty name="Controllers"  type="struct"           getter="false" setter="false" />
    <cfproperty name="Services"     type="ServiceLocator"   getter="false" setter="false" />

    <cffunction access="public" name="init" returntype="MVC" output="false" >
        <cfargument type="string" name="pathToControllers" required="true" />
        <cfargument type="string" name="absoluteWebRootPath" required="true" />
        <cfargument type="ServiceLocator" name="services" required="true" />

        <cfscript>
        variables.Services = arguments.services;
        var ControllersOnDisk = directoryList(arguments.pathToControllers, true, "path", "*.cfc", null, "file");
        var ControllerList = {};

        for(var CurrentControllerPath in ControllersOnDisk)
        {
            var TransformedPath = CurrentControllerPath.replace(arguments.absoluteWebRootPath, "").replace("/", ".", "ALL").replace(".cfc", "");
            var Metadata = getComponentMetadata(transformedPath);
            var ControllerName = listLast(metadata.name, ".");
            ControllerList[controllerName] = [];

            for(var CurrentFunction in metadata.functions)
            {
                if (CurrentFunction.access == "public")
                    ControllerList[controllerName].append(CurrentFunction.name);
            }
        }

        variables.Controllers = controllerList;
        return this;
        </cfscript>
    </cffunction>

    <cffunction access="public" name="ResolveRequest" returntype="MVC.ResponseContext" output="false" >
        <cfargument name="context" type="MVC.RequestContext" required="true" />

        <cfscript>
            var Response = new MVC.ResponseContext();

            if (!ResolveAction(Response, arguments.context))
                return Response;

            if (!ValidateController(Response, arguments.context))
                return Response;

            DoController(Response, arguments.context);
            return Response;
        </cfscript>
    </cffunction>

    <cffunction access="private" name="ResolveAction" returntype="boolean" output="false" >
        <cfargument name="response" type="MVC.ResponseContext" required="true" />
        <cfargument name="context" type="MVC.RequestContext" required="true" />

        <cfscript>
        if (!structKeyExists(arguments.context.GetURL(), "action"))
        {
            arguments.response.SetStatusCode(400);
            arguments.response.SetBody("<p style='background-color: red; color: white;' >ERROR: Param 'action' missing from URL</p>");
            return false;
        }

        var Action = arguments.context.GetURL().action;
        structDelete(arguments.context.GetURL(), "action");
        var Actions = listToArray(Action, ".", false);

        if (Action.len() == 0)
        {
            arguments.response.SetStatusCode(400);
            arguments.response.SetBody("<p style='background-color: red; color: white;' >ERROR: URL-param 'action' is empty</p>");
            return false;
        }

        arguments.context.SetController(Actions[1]);
        arguments.context.SetItem(Actions.len() GT 1 ? Actions[2] : "default");

        return true;
        </cfscript>
    </cffunction>

    <cffunction access="private" name="ValidateController" returntype="boolean" output="false" >
        <cfargument name="response" type="MVC.ResponseContext" required="true" />
        <cfargument name="context" type="MVC.RequestContext" required="true" />

        <cfscript>
            if (!structKeyExists(variables.Controllers, arguments.context.GetController()))
            {
                arguments.response.SetStatusCode(400);
                arguments.response.SetBody("<p style='background-color: red; color: white;' >ERROR: No available controllers by the name of '#arguments.context.GetController()#'</p>");
                return false;
            }

            if (arguments.context.GetItem() == "default") return true;

            if (arrayFind(variables.Controllers[arguments.context.GetController()], arguments.context.GetItem()) == 0)
            {
                arguments.response.SetStatusCode(400);
                arguments.response.SetBody("<p style='background-color: red; color: white;' >ERROR: No available items in controller '#arguments.context.GetController()#' by the name of '#arguments.context.GetItem()#'</p>");
                return false;
            }

            return true;
        </cfscript>
    </cffunction>

    <cffunction access="private" name="DoController" returntype="void" output="false" >
        <cfargument name="response" type="MVC.ResponseContext" required="true" />
        <cfargument name="context" type="MVC.RequestContext" required="true" />

        <cfscript>
            var Controller = createObject("Controllers.#arguments.context.GetController()#").init(variables.Services);
            invoke(Controller, arguments.context.GetItem(), {"context": arguments.context, "response": arguments.response});
        </cfscript>
    </cffunction>

</cfcomponent>