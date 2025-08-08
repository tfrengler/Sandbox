component displayname="Trail" modifier="abstract" output="false" accessors="false" persistent="true" {

    static {
        static.viewPassthrough = true;  // Makes it so that any request outside index.cfm is not handled by Trail but simply cfincluded as normal
        static.debugMode = true;       // Enables debug mode which among other things logs initialization of routes and endpoints
    }

    public void function onRequest(required string targetPage) output=true {

        if ((static.viewPassthrough && right(targetPage, 9) != "index.cfm") || right(targetPage, 9) == "debug.cfm") {
            cfmodule(template=#arguments.targetPage#);
            abort;
        }

        if (!structKeyExists(URL, "trail")) {
            cfheader(statuscode=400);
            cfcontent(reset=true);
            writeOutput("<span style='background-color:red;color:white;'>Trail says: bad request</span>");
            abort;
        }

        var trailTarget = URL.trail;
        var controller = {};
        var foundRoute = false;

        for (var route in application.Trail.Routes) {
            if ( left(trailTarget, len(route)) == route ) {
                foundRoute = true;
                controller = application.Trail.Routes[route];
                break;
            }
        }

        if (!foundRoute) {
            cfcontent(reset=true);
            writeOutput("<span style='background-color:red;color:white;'>Trail says: no route configured to handle request</span>");
            abort;
        }

        var endpointData = {};
        var endpointMatched = false;
        var isAPIController = controller.type == "api";

        for(var endpoint in controller.endpoints) {
            endpointData = controller.endpoints[endpoint];

            if (reMatch(endpoint, trailTarget).len() > 0) {
                endpointMatched = true;
                break;
            }
        }

        if (!endpointMatched) {
            cfcontent(reset=true);
            writeOutput("<span style='background-color:red;color:white;'>No endpoint configured to handle request within route</span>");
            abort;
        }

        if (isAPIController) {
            if (!structKeyExists(endpointData, CGI.REQUEST_METHOD)) {
                cfcontent(reset=true);
                writeOutput("<span style='background-color:red;color:white;'>No endpoint configured to handle request method #CGI.REQUEST_METHOD# within route</span>");
                abort;
            }
            endpointData = endpointData[CGI.REQUEST_METHOD];
        }

        var variableSearch = reFind(
            reg_expression=endpoint,
            string=trailTarget,
            returnsubexpressions=true,
            scope="one"
        );

        var trailArguments = {};

        for (var i = 2; i < len(variableSearch.match) + 1; i++) {
            trailArguments[ endpointData.variables[i-1] ] = variableSearch.match[i];
        }

        var trailController = createObject("component", controller.controller);
        var result = invoke(trailController, endpointData.function, trailArguments);

        cfcontent(reset=true);
        writeOutput(result);
    }

    public void function onApplicationStart() output = false {

        application.Trail = {};
        application.Trail.Initialized = now();
        application.Trail.Routes = {};
        application.Trail.Log = [];

        var baseDir = expandPath("/");

        var allCFCs = directoryList(
            path=baseDir,
            recurse=true,
            listInfo="path",
            filter="*.cfc",
            type="file"
        );

        for (var currentCFC in allCFCs) {

            if (right(currentCFC, 15) == "application.cfc") {
                WriteToLog("WARN: Skipping #currentCFC#");
                continue;
            }

            var dottedPath = currentCFC
                .replace(baseDir, "")
                .replace("\", ".", "all")
                .replace("/", ".", "all")
                .replace(".cfc", "");

            try {
                var metadata = getComponentMetadata(dottedPath);
            }
            catch (any error) {
                WriteToLog("ERROR: Exception encountered when getting metadata of component #currentCFC# (#error.Message#)");
                continue;
            }

            if (structKeyExists(metadata, "trail")) {
                WriteToLog("BEGIN: Found Trail controller: #dottedPath# (#currentCFC#)");
                ParseController(metadata);
            }
        }
    }

    private void function ParseController(required struct metadata) output = false {

        if (!structKeyExists(arguments.metadata, "trailroute")) {
            WriteToLog("ERROR: Trail controller has no route annotated, skipping");
            return;
        }

        var route = arguments.metadata.trailroute;

        if (len(route) > 1 && (left(route, 1) == '/' || right(route, 1) == '/')) {
            WriteToLog("ERROR: Trail controller #arguments.metadata.name# has a route with a leading and/or trailing slash, skipping: #route#");
            return;
        }

        var isAPIController = false;
        var isViewController = false;
        var controllerType = "";

        if (structKeyExists(arguments.metadata, "trailview")) {
            WriteToLog("Trail controller is a view");
            isViewController = true;
            controllerType = "view";
        }
        else if (structKeyExists(arguments.metadata, "trailapi")) {
            WriteToLog("Trail controller is an API");
            isAPIController = true;
            controllerType = "api";
        }

        if (!isAPIController && !isViewController) {
            WriteToLog("ERROR: Trail controller is missing the annotation indicating its type, skipping");
            return;
        }

        if (structKeyExists(application.Trail.Routes, route)) {
            WriteToLog("ERROR: Trail controller with this route already exists, skipping: #application.Trail.Routes[route].Controller#");
            return;
        }

        application.Trail.Routes[route] = {
            Controller: arguments.metadata.fullname,
            Type: controllerType,
            Endpoints: {}
        };

        var endpointCollection = application.Trail.Routes[route].Endpoints;
        ParseEndpoints(route, endpointCollection, metadata.functions, isAPIController);
    }

    private void function ParseEndpoints(required string route, required struct endpointCollection, required array functionMetadata, required boolean isAPI) output = false {

        for (var currentFunction in arguments.functionMetadata) {

            if (!structKeyExists(currentFunction, "trailendpoint")) {
                continue;
            }

            var endpointPath = currentFunction.trailendpoint;
            WriteToLog("BEGIN: Found a Trail endpoint: #currentFunction.name#, with path: #endpointPath#");

            if (len(endpointPath) > 1 && (left(endpointPath, 1) == '/' || right(endpointPath, 1) == '/')) {
                WriteToLog("ERROR: Trail endpoint has a path with a leading and/or trailing slash, skipping");
                continue;
            }

            var endpointData = {
                Name: endpointPath,
                Function: currentFunction.name,
                Variables: []
            };

            var regexPath = ParsePathVariables(arguments.route, endpointData);

            if (arguments.isAPI) {
                var endpointMethod = "GET";
                if (structKeyExists(currentFunction, "trailmethod")) {
                    endpointMethod = currentFunction.trailmethod;
                }
                arguments.endpointCollection[regexPath][endpointMethod] = endpointData;
                WriteToLog("HTTP request method for API endpoint is mapped to: #endpointMethod#");
            }
            else {
                if (structKeyExists(arguments.endpointCollection, regexPath)) {
                    WriteToLog("ERROR: Endpoint view with the same path already mapped, skipping: #arguments.endpointCollection[regexPath].Function#");
                    continue;
                }

                arguments.endpointCollection[regexPath] = endpointData;
            }

            WriteToLog("SUCCESS: Trail endpoint mapped");
        }

        if (structIsEmpty(arguments.endpointCollection)) {
            WriteToLog("ERROR: No endpoints found in controller");
            structDelete(application.Trail.Routes, route);
            return;
        }

        WriteToLog("SUCCESS: Route mapped");
    }

    /**
     * @hint Parses potential variables in the path and returns the endpoint path that requests will be matched against with all variables replaced with regex captures.
     */
    private string function ParsePathVariables(required string route, required struct endpointData) output = false {

        var endpointPath = arguments.endpointData.name;
        var pathVariableSearch = reFind(
            reg_expression="\{(\w+)\}",
            string=endpointPath,
            returnsubexpressions=true,
            scope="all"
        );

        var regexPath = endpointPath;
        var pathVariables = [];

        for (var results in pathVariableSearch) {

            if (arrayLen(results.match) == 1) {
                continue;
            }

            pathVariables.append(results.match[2]);
            WriteToLog("Found and parsed a path variable: #results.match[2]#");
            regexPath = replace(regexPath, results.match[1], "([^\/]+)");
        }

        regexPath = "^#arguments.route#/#regexPath#$";

        if (endpointPath == '/') {
            regexPath = "^#arguments.route#$";
        }

        arguments.endpointData.variables = pathVariables;
        return regexPath;
    }

    private void function WriteToLog(required string message) output = false {
        if (!static.debugMode || len(message.trim()) == 0) return;
        application.Trail.Log.append(arguments.message);
    }
}