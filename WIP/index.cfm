<!--- <cfset folder = "/mnt/NAS_Backup/Thomas2/Music/-Classical/" />

<cfset Test = directorylist(
    path=folder,
    recurse=true,
    listInfo="query",
    type="file",
    filter="*.mp3"
) /> --->

<cfset root = getDirectoryFromPath(getCurrentTemplatePath()) />
<cfset Logger = new LogManager(root, "html") />
<cfset Logger.Information("Test!", "Thomas") />

<!--- <cftry>
    <cfexecute name="ffmpeg" arguments="-i ""/mnt/NAS_Backup/Thomas2/Music/-Classical/Classical Music Top 100 (1996)/Albinoni - Adagio In Sol Minore.mp3"" #root#/Test.wav" variable="ffmpeg" errorVariable="ffmpeg_error" timeout="5" />

<cfcatch type="lucee.runtime.exp.ApplicationException">
    <cfdump label="OK" var=#ffmpeg# />
    <cfdump label="NOK" var=#ffmpeg_error# />

    <!--- <cfrethrow/> --->
    <cfset getFileInfo("/mnt/NAS_Backup/Thomas2/Music/-Classical/Classical Music Top 100 (1996)/Albinoni - Adagio In Sol Minore.mp3") />
</cfcatch>
</cftry> --->

<cfabort/>

<!--- sudo mount -t cifs -o username=admin //192.168.1.84/home/Backup /mnt/NAS_Backup/ --->
<!--- "/mnt/NAS_Backup/Thomas2/Music/-Classical/Classical Music Top 100 (1996)/Albinoni - Adagio In Sol Minore.mp3" --->