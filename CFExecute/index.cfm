<!--- <cfset PWSHCommand = toBase64("C:\Users\Thomas` Frengler\tools\dotnet-script.exe --version", "UTF-16LE") />
<cfdump var=#PWSHCommand# />

<cfset Using_ProcessBuilder = createObject("java", "java.lang.ProcessBuilder") />
<cfset Builder = Using_ProcessBuilder.init(["pwsh.exe", "-EncodedCommand", PWSHCommand, "-OutputFormat", "Text", "-InputFormat", "none"]) />
<cfset OutputFile = createObject("java", "java.io.File").init("C:\Dev\web\Sandbox\Log.txt") />
<cfset Builder.redirectOutput(OutputFile) />
<cfset Builder.redirectErrorStream(true) />
<cfset Process = Builder.start() />
<cfset ExitCode = Process.WaitFor() />

<cfdump var=#ExitCode# /> --->

<!--- In order for this to work:
    - This was mostly a permissions/environment variable issue
    - "dotnet script" is only available if you have the right env vars,
      in my case PATH must include "C:\Users\Thomas Frengler\.dotnet\tools\" and "C:\Program Files\dotnet\;"
      which you can set inside of a Powershell-script (using "$env:PATH='blahblah'")
    - The user running Lucee also needs read-permissions on the dotnet folder ("C:\Users\Thomas Frengler\.dotnet" in my case)
    - Be aware that the PS script and subsequent CSX script are run with the same permissions as cfexecute
--->

<cfexecute
    name="pwsh"
    arguments=#["-OutputFormat", "Text", "C:\Dev\web\Sandbox\test.ps1 'C:\Dev\web\Sandbox\EnumerateTests.csx'"]#
    variable="test"
    errorVariable="error"
    timeout="15"
    terminateOnTimeout="true"
/>

<cfdump label="test" var=#test# />
<cfdump label="error" var=#error# />

<cfdump var=#deserializeJSON(trim(test))# />