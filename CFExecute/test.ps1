$env:Path = "C:\Program Files\dotnet\;C:\Users\Thomas Frengler\.dotnet\tools;"
$ScriptFile = $args[0]; #'C:\Dev\web\Sandbox\EnumerateTests.csx'

if (![System.IO.File]::Exists($ScriptFile))
{
    throw "File does not exist: " + $ScriptFile
}

dotnet script $ScriptFile