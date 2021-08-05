<!---
/*  MACRO'S
*   This class contains the logic for resolving macros - strings that are essentially methods with (optionally) arguments - used for generating or fetching dynamic data.
*   There are two public methods for resolving macros that should be used:
*   1: ResolveMacroString - for a string that is a single macro, such as: "<:ZAAK_NUMMER[LATEST]:>"
*   2: ResolveMacroInterpolatedString - for a string that contains one or more macros, such as: "You can expect your delivery on <:DATE[TODAY+2D]:>, between 8 and 12"
*
*   These two are typically called automatically by step definitions using Specflow's step transformation tools. But you are of course free to call them directly as well
*   for certain situations. Below is a list of supported macros:
*
*   <:DATE[TODAY|TODAY+1W]:> - see GetDate() for more info about the argument syntax
*   <:NUMBER[RANDOM|X,Y]:> - X and Y being two non-negative numbers
*   <:PEUTER_KENMERK[RANDOM|LATEST]:> - "LATEST" extracts the peuter kenmerk from the DashboardData-instance
*   <:ZAAK_NUMMER[LATEST]:> - Similar to above
*   <:RANDOM_STRING[X]:> - See GetRandomString(), X is the length of the string you want
*   <:STRING_DATA[XXX]:> - Attempts to retrieves a string from the static StringDataBucket-class with XXX being the label given to the data
*   <:BEDRIJFSREGEL[XXX,YYY-000,ZZZ,...]:> - Retrieves static data about a specific part of a bedrijfsregel in a product. See GemDenHaag.Data.Bedrijfsregels.Bedrijfsregels.Get() for an in-depth explanation
*   XXX is the product name, YYY is the bedrijfsregel code, ZZZ is the part of the bedrijfsregel you want and ... is a list of values to interpolate (if the bedrijfsregel text or toelichting has any dynamic values ofc)
*
*   NOTE: CreateReplacementValue() contains the switch for what happens per macro

#region INTERNAL MACRO FUNCTIONALITY

private sealed class Macro
{
    public string InputString;
    public string MethodName;
    public string[] Arguments;
    public string Replacement;
}

private Dictionary<string, Macro> CollectMacros(string input)
{
    input = input.Trim();

    var MacroPattern = new Regex(@"<:(.*):>");
    MatchCollection Matches = MacroPattern.Matches(input);
    if (Matches.Count == 0) return null;

    var ReturnData = new Dictionary<string, Macro>(Matches.Count);

    foreach (Match Match in Matches)
        if (!ReturnData.ContainsKey(Match.Groups[1].Value))
            ReturnData.Add(Match.Groups[1].Value, new Macro() { InputString = Match.Groups[1].Value });

    return ReturnData;
}

private void ExtractMethodAndArguments(Macro macro)
{
    var MethodAndArgumentsPattern = new Regex(@"(^\w+)\[(.*)\]|(^\w+)");
    Match Match = MethodAndArgumentsPattern.Match(macro.InputString);

    string Method = null;

    if (Match.Groups[1].Value != string.Empty)
    {
        Method = Match.Groups[1].Value;
    }
    else if (Match.Groups[3].Value != string.Empty)
        Method = Match.Groups[3].Value;

    if (Match.Groups[2].Value != string.Empty)
    {
        macro.Arguments = Match.Groups[2].Value.Split(',', StringSplitOptions.RemoveEmptyEntries);
        macro.Arguments.Select(argument => argument.Trim()).ToArray();
    }

    macro.MethodName = Method;
}

private void CreateReplacementValue(Macro macro)
{
    switch (macro.MethodName)
    {
        case "DATE": // "<:DATE[TODAY|TODAY+1W,yyyy-mm-dd]:>" Note that the second argument is the date form and you can chose what you want. See https://docs.microsoft.com/en-us/dotnet/api/system.globalization.datetimeformatinfo?view=net-5.0#examples
            ExpectMacroArguments(macro);
            macro.Replacement = GetDateString(macro.Arguments[0], macro.Arguments.Length > 1 ? macro.Arguments[1] : null);
            break;

        case "NUMBER": // <:NUMBER[RANDOM|1,10]:>
            ExpectMacroArguments(macro);
            if (macro.Arguments[0] == "RANDOM")
            {
                macro.Replacement = Convert.ToString(GetRandomNumber());
                break;
            }

            if (macro.Arguments.Length < 2)
                throw new Exception("NUMBER macro must have at least two arguments: " + macro.InputString);

            uint MinNumber = Convert.ToUInt32(macro.Arguments[0]);
            uint MaxNumber = Convert.ToUInt32(macro.Arguments[1]);

            macro.Replacement = Convert.ToString(GetRandomNumber(MinNumber, MaxNumber));
            break;

        case "PEUTER_KENMERK": // <:PEUTER_KENMERK[RANDOM|LATEST]:>
            ExpectMacroArguments(macro);

            if (macro.Arguments[0] == "LATEST")
            {
                macro.Replacement = DashboardData.PeuterKenmerk;
                break;
            }

            if (macro.Arguments[0] == "RANDOM")
            {
                macro.Replacement = macro.Arguments.Length > 1 ? GetRandomPeuterKenmerk(macro.Arguments[1]) : GetRandomPeuterKenmerk();
                break;
            }

            throw new Exception("Invalid argument for macro PEUTER_KENMERK: " + macro.Arguments[0]);

        case "ZAAK_NUMMER": // <:ZAAK_NUMMER[LATEST]:>
            ExpectMacroArguments(macro);
            macro.Replacement = DashboardData.Zaaknummer;
            break;

        case "RANDOM_STRING": // <:RANDOM_STRING[X]:>
            ExpectMacroArguments(macro);
            macro.Replacement = GetRandomString( Convert.ToUInt32(macro.Arguments[0]) );
            break;

        case "STRING_DATA": // <:STRING_DATA[XXX]:>
            ExpectMacroArguments(macro);
            macro.Replacement = StringDataBucket.Get(macro.Arguments[0]);
            break;

        case "BEDRIJFSREGEL":
            ExpectMacroArguments(macro);
            ResolveMacroReplacement_BEDRIJFSREGEL(macro);
            break;

        default:
            throw new NotImplementedException("Not a valid macro: " + macro.InputString);
    };

    Console.WriteLine($"Resolved macro: {macro.InputString} = {macro.Replacement}");
}

private void ResolveMacroReplacement_BEDRIJFSREGEL(Macro macro)
{

    if (macro.Arguments.Length < 3)
        throw new Exception("Error resolving macro 'BEDRIJFSREGEL'. We expected there to be 3 arguments: " + macro.InputString);

    string[] DynamicValues = null;

    if (macro.Arguments.Length > 3)
    {
        DynamicValues = new string[macro.Arguments.Length - 3];
        uint DynamicValuesIndex = 0;

        for (uint Index = 3; Index < macro.Arguments.Length; Index++)
        {
            try
            {
                DynamicValues[DynamicValuesIndex] = ResolveMacroString(macro.Arguments[Index]);
            }
            catch (NotImplementedException)
            {
                DynamicValues[DynamicValuesIndex] = macro.Arguments[Index];
            }
        }
    }

    macro.Replacement = BedrijfsRegelsData.Get(macro.Arguments[0], macro.Arguments[1], macro.Arguments[2], DynamicValues);
}

private string GetMacroReplacedString(string inputString, in Dictionary<string, Macro> replacements)
{
    string ReturnData = inputString.Replace("<:", "").Replace(":>", "");

    foreach (KeyValuePair<string, Macro> CurrentReplacement in replacements)
        ReturnData = ReturnData.Replace(CurrentReplacement.Key, CurrentReplacement.Value.Replacement);

    return ReturnData.Trim();
}

private void ExpectMacroArguments(Macro macro)
{
    if (macro.Arguments == null || macro.Arguments != null && macro.Arguments.Length == 0)
        throw new Exception($"Expected macro '{macro.InputString}' to have arguments, but there are none");
}

#endregion

#region PUBLIC MACRO INTERFACES

/// <summary>
/// Used to resolve a string that is a single macro. You can pass the macro either with or without the macro delimiters (&lt;: and :&gt;)
/// </summary>
/// <param name="input">A single macro string</param>
/// <returns>A new string, with the value replacing the input string. Throws an exception if the string is not a valid macro</returns>
public string ResolveMacroString(string input)
{
    input = input.Replace("<:", "").Replace(":>", "").Trim();
    var Macro = new Macro() { InputString = input };

    ExtractMethodAndArguments(Macro);
    CreateReplacementValue(Macro);

    return Macro.Replacement;
}

/// <summary>
/// Similar to <see cref="ResolveMacroString"/> except this replaces multiple macros found within the input string
/// </summary>
/// <param name="input">A string containing one or more macros</param>
/// <returns>A copy of the original string, with all recognized macros replaced. If no macros are found it simply returns the original string</returns>
public string ResolveMacroInterpolatedString(in string input)
{
    Dictionary<string, Macro> Macros = CollectMacros(input);
    if (Macros == null)
        return input;

    Console.WriteLine($"ResolveMacroInterpolatedString: found {Macros.Count} macro(s) in string, attempting to resolve");

    foreach (var CurrentMacro in Macros)
    {
        ExtractMethodAndArguments(CurrentMacro.Value);
        CreateReplacementValue(CurrentMacro.Value);
    }

    return GetMacroReplacedString(input, Macros);
}

/// <summary>Helper function for test steps to generate random numbers</summary>
/// <param name="value">Format is: RANDOM(min,max). If you don't care about the range, just pass RANDOM to get a completely random number</param>
/// <returns>A non-negative 32-bit number</returns>
public int GetRandomNumber(string value)
{
    if (value == "RANDOM")
        return RandomNumbers.Next();

    var Pattern = new Regex(@"RANDOM\((\d+),(\d+)");
    Match Matches = Pattern.Match(value);

    int FirstNumber = int.Parse(Matches.Groups[1].Value);
    int SecondNumber = int.Parse(Matches.Groups[2].Value);

    return RandomNumbers.Next(FirstNumber, SecondNumber);
}

/// <summary>
/// Helper function for test steps to create dynamic dates using a string pattern
/// </summary>
/// <param name="date">
/// <para>The date as a string pattern: TODAY{operator}{amount}{datepart}.</para>
/// <para>Pass for example "TODAY+1W" to get a date one week from now. You can also pass "TODAY" to get today's date</para>
/// <para>'operator' can be + or -</para>
/// <para>'amount' should be an unsigned number (from 0 up to 255)</para>
/// <para>'datepart' can be D (days), W (weeks), M (months) or Y (years). If you pass multiple, only the first will be used</para>
/// </param>
/// <returns>A DateTime object relative to today's date based on the input</returns>
public static DateTime GetDate(string date)
{
    if (date == "TODAY")
        return DateTime.Now.Date;

    var Pattern = new Regex(@"TODAY(\D{1})(\d+)(\w{1})");
    Match Matches = Pattern.Match(date);

    char Operator = Matches.Groups[1].Value[0];
    byte Amount = byte.Parse(Matches.Groups[2].Value); // We are making a hardcoded choice to not let people pass a number larger than 255
    char DatePart = char.ToUpper(Matches.Groups[3].Value[0]);

    char[] ValidOperators = new char[] { '-', '+' };

    if (Array.IndexOf(ValidOperators, Operator) == -1)
        throw new Exception("Invalid operator part: " + Operator);

    var ReturnData = DatePart switch
    {
        'D' => DateTime.Now.Date.AddDays(float.Parse($"{Operator}{Amount}")),
        'W' => DateTime.Now.Date.AddDays(float.Parse($"{Operator}{Amount * 7}")),
        'M' => DateTime.Now.Date.AddMonths(int.Parse($"{Operator}{Amount}")),
        'Y' => DateTime.Now.Date.AddYears(int.Parse($"{Operator}{Amount}")),
        _ => throw new Exception("Invalid date part: " + DatePart),
    };

    return ReturnData;
}

/// <summary>
/// Helper function for test steps to create dynamic dates using a string pattern. Same as GetDate() but returns a string. If the date string does not start with "TODAY" then the original string is returned.
/// </summary>
/// <param name="date">See GetDate's date-argument</param>
/// <param name="format">The format to return the date-string in. Optional, defaults to <see cref="CVS.DateFormat"/></param>
/// <returns>A string representation of a date relative to today's date based on the input</returns>
public static string GetDateString(string date, string format = null)
{
    if (date.Length < 5) return date;
    if (date.Substring(0, 5) != "TODAY") return date;

    string ReturnData = GetDate(date).ToString(format ?? CVS.DateFormat);

    return ReturnData;
}

/// <summary>
/// Helper method to generate a random alpha-numerical string of a certain length
/// </summary>
/// <param name="length">The length you want the random string to be</param>
/// <returns>A string containing alpha-numerical values</returns>
public static string GetRandomString(uint length)
{
    string Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
    var StringChars = new char[length];
    var Random = new Random();

    for (int i = 0; i < StringChars.Length; i++)
    {
        StringChars[i] = Chars[Random.Next(Chars.Length)];
    }

    return new String(StringChars);
}
--->

<!--- <cfset someVar = createObject("java", "java.nio.file.Files").readAllLines() />
<cfset var oRegexPattern = createObject("java", "java.util.regex.Pattern") />
    <cfset var stReturnData = {} />

    <cfloop array=#arguments.macros# index="sCurrentMacro" >

        <cfset structInsert(stReturnData, sCurrentMacro, "") />

        <cfset sCleanMacro = replace(sCurrentMacro, ".", "\.", "ALL") />
        <cfset oPattern = oRegexPattern.Compile("\{:#sCleanMacro#=>(?!:})(.+?):\}") />
        <cfset oPatternMatcher = oPattern.Matcher(javacast("string", arguments.text)) />

        <cfif NOT oPatternMatcher.Find() >
            <cfcontinue/>
        </cfif>

        <cfset stReturnData[sCurrentMacro] = oPatternMatcher.group(1) />
    </cfloop>

private sealed class Macro
{
    public string InputString;
    public string MethodName;
    public string[] Arguments;
    public string Replacement;
}

{
    <!--- MACROS --->
    private Dictionary<string, Macro> CollectMacros(string input)
    private void ExtractMethodAndArguments(Macro macro)
    private void CreateReplacementValue(Macro macro)
    private string GetMacroReplacedString(string inputString, in Dictionary<string, Macro> replacements)
    public string ResolveMacroString(string input)
    public string ResolveMacroInterpolatedString(in string input)

    <!--- UTILS --->
    public int GetRandomNumber(string value)
    public static DateTime GetDate(string date)
    public static string GetDateString(string date, string format = null)
    public static string GetDateInterpolatedString(string inputString, string format = null)
    public static string GetRandomString(uint length)
}
--->

<cfset MacroEngine = new MacroEngine() />

<!--- <cfset JsonData = fileRead("testdata.json") />
<cfdump var=#deserializeJSON(JsonData)# />

<hr/>

<cfset Test = MacroEngine.ResolveMacroInterpolatedString(JsonData) />
<cfdump var=#deserializeJSON(Test)# /> --->

<cfset writeDump(MacroEngine.GetRandomNumber(1,10)) />
