<cfcomponent persistent="true" output="true" modifier="final" >

    <!--- CONSTRUCTOR --->

    <cffunction name="init" access="public" returntype="MacroEngine" output="false" hint="Constructor" >
        <cfreturn this />
    </cffunction>

    <!--- PRIVATE --->

    <cffunction name="CollectMacros" access="private" returntype="struct" output="false" hint="" >
        <cfargument name="input" type="string" required="true" hint="" />
        <cfscript>
        arguments.input = trim(arguments.input);

        var JavaRegex = createObject("java", "java.util.regex.Pattern");
        var MacroPattern = JavaRegex.Compile("<:(.*):>");
        var PatternMatcher = MacroPattern.Matcher(javacast("string", arguments.input));
        var ReturnData = {};

        while(PatternMatcher.find())
        {
            ReturnData[PatternMatcher.group(1)] =
            {
                "InputString": PatternMatcher.group(1),
                "MethodName": "",
                "Arguments": [],
                "Replacement": ""
            }
        }

        return ReturnData;
        </cfscript>
    </cffunction>

    <cffunction name="ExtractMethodAndArguments" access="private" returntype="void" output="false" hint="" >
        <cfargument name="macroData" type="struct" required="true" hint="" />
        <cfscript>

        var JavaRegex = createObject("java", "java.util.regex.Pattern");
        var MethodAndArgumentsPattern = JavaRegex.Compile("(^\w+)\[(.*)\]|(^\w+)");
        var PatternMatcher = MethodAndArgumentsPattern.Matcher(javacast("string", arguments.macroData.InputString));

        PatternMatcher.find();
        if (!isNull(PatternMatcher.group(1)))
            arguments.macroData.MethodName = PatternMatcher.group(1);
        else
            arguments.macroData.MethodName = PatternMatcher.group(3);

        if (!isNull(PatternMatcher.group(2)))
            arguments.macroData.Arguments = listToArray(PatternMatcher.group(2), ",", false);
        </cfscript>
    </cffunction>

    <cffunction name="CreateReplacementValue" access="private" returntype="void" output="false" hint="" >
        <cfargument name="macroData" type="struct" required="true" hint="" />
        <cfscript>
            switch (arguments.macroData.MethodName) {
                case "TEST_ID_NAME":
                    arguments.macroData.Replacement = "SOME ID";
                    break;

                case "DATE":
                    arguments.macroData.Replacement = "SOME DATE";
                    break;

                case "RANDOM_NUMBER":
                    var Params = {};
                    if (arguments.macroData.Arguments.len() > 0)
                    {
                        Params.firstNumber = arguments.macroData.Arguments[1];
                        Params.secondNumber = arguments.macroData.Arguments[2];
                    }
                    arguments.macroData.Replacement = GetRandomNumber(argumentCollection=Params);
                    break;

                case "RANDOM_STRING":
                    arguments.macroData.Replacement = "SOME STRING";
                    break;

                default:
                    throw(message="Error resolving macro", detail="#arguments.macroData.MethodName# is not a recognized macro");
            }
        </cfscript>
    </cffunction>

    <cffunction name="GetMacroReplacedString" access="private" returntype="string" output="false" hint="" >
        <cfargument name="input" type="string" required="true" hint="" />
        <cfargument name="replacements" type="struct" required="true" hint="" />
        <cfscript>

        arguments.input = trim(arguments.input.replace("<:", "", "ALL").replace(":>", "", "ALL"));

        for(var CurrentReplacement in arguments.replacements)
            arguments.input = arguments.input.replace(CurrentReplacement, arguments.replacements[CurrentReplacement].Replacement, "ALL");

        return trim(arguments.input);
        </cfscript>
    </cffunction>

    <!--- MACROS - PUBLIC --->

    <cffunction name="ResolveMacroString" access="public" returntype="string" output="false" hint="Used to resolve a string that is a single macro. You can pass the macro either with or without the macro delimiters (<: and :>). Throws an exception if the string is NOT a macro" >
        <cfargument name="input" type="string" required="true" hint="" />
        <cfscript>

        arguments.input = trim(arguments.input.replace("<:", "").replace(":>", ""));
        var Macro = {
            "InputString": arguments.input,
            "MethodName": "",
            "Arguments": [],
            "Replacement": ""
        };

        ExtractMethodAndArguments(Macro);
        CreateReplacementValue(Macro);

        return Macro.Replacement;
        </cfscript>
    </cffunction>

    <cffunction name="ResolveMacroInterpolatedString" access="public" returntype="string" output="false" hint="Similar to ResolveMacroString except this replaces multiple macros found within the input string. If no macros are found the original string is returned" >
        <cfargument name="input" type="string" required="true" hint="" />
        <cfscript>

        var Macros = CollectMacros(arguments.input);
        if (structIsEmpty(Macros))
            return arguments.input;

        for(var CurrentMacro in Macros)
        {
            ExtractMethodAndArguments(Macros[CurrentMacro]);
            CreateReplacementValue(Macros[CurrentMacro]);
        };

        return GetMacroReplacedString(arguments.input, Macros);
        </cfscript>
    </cffunction>

    <!--- UTILS - PUBLIC --->

    <cffunction name="GetRandomNumber" access="public" returntype="numeric" output="false" hint="Helper function for test steps to generate random numbers. If you pass a start- and end-range the numbers are inclusive" >
        <cfargument name="firstNumber" type="numeric" required="false" hint="" />
        <cfargument name="secondNumber" type="numeric" required="false" hint="" />

        <cfscript>
            if (structIsEmpty(arguments))
                return randRange(1,100000000);

            return randRange(arguments.FirstNumber, arguments.SecondNumber);
        </cfscript>
    </cffunction>

    <cffunction name="GetRandomString" access="public" returntype="string" output="false" hint="Helper method to generate a random alpha-numerical string of a certain length" >
        <cfargument name="length" type="numeric" required="true" hint="" />
        <cfscript>

            var AvailableChars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
            var StringChars = []

            var Index = 1;
            var Limit = arguments.length + 1;

            while(Index < Limit)
            {
                StringChars.append(AvailableChars[randRange(1,AvailableChars.len())]);
                Index++;
            }

            return arrayToList(StringChars, "");
        </cfscript>
    </cffunction>

</cfcomponent>