<cfscript>

// inputString = "C:\temp\\test1//test2/test3\/test4/\test5/test6///test7\\\test8\";
// firstPass = reReplace(inputString, "\\", "/", "ALL");
// secondPass = reReplace(firstPass, "/{2,}", "/", "ALL");
// thirdPass = reReplace(secondPass, "/$", "");

// writeDump(thirdPass);
// abort;

CacheFolderContents = directorylist(
    path="D:\Music\-Classical\Classical Music Top 100 (1996)\",
    recurse=false,
    listInfo="array",
    type="file"
);

// writeDump(var=CacheFolderContents, abort="true");
writeDump(hash(CacheFolderContents[1], "SHA"));
writeDump(hash(CacheFolderContents[2], "SHA"));
writeDump(hash(CacheFolderContents[3], "SHA"));
writeDump(hash(CacheFolderContents[4], "SHA"));
writeDump(hash(CacheFolderContents[5], "SHA"));
writeOutput("<hr/>")
root = getDirectoryFromPath(getCurrentTemplatePath());

Logger = new Logger();
// maxSize=2 * 1024 * 1024 * 1024
WAVCache = new WAVCache(cacheFolder="C:\Temp\WavCache", fileManifest=CacheFolderContents, logger=Logger);

File1 = WAVCache.Get("2B9DC44A6AEB7BF2A377C910CADA5C2B1558128B");
File2 = WAVCache.Get("78F270D2C2D4ADFAE20A179F0734614A2A817083");
File3 = WAVCache.Get("447799354F83DBE8908A3E20E2064E6CB7F7043F");
File4 = WAVCache.Get("038CBE3904D6081C713A2E3053A8CD53AF8F79ED");
File5 = WAVCache.Get("20BCB15CE78F51685DB60EC7DCDFD07C57458973");

sleep(2000);
// writeDump(File);
</cfscript>
<!--- <cfoutput>
    <section>
        <audio controls src='#File.FilePath#'></audio>
    </section>
</cfoutput> --->

<!--- <cftry>
    <cfexecute name="ffmpeg" arguments="-i ""/mnt/NAS_Backup/Thomas2/Music/-Classical/Classical Music Top 100 (1996)/Albinoni - Adagio In Sol Minore.mp3"" #root#/Test.wav" variable="ffmpeg" errorVariable="ffmpeg_error" timeout="5" />

<cfcatch type="lucee.runtime.exp.ApplicationException">
    <cfdump label="OK" var=#ffmpeg# />
    <cfdump label="NOK" var=#ffmpeg_error# />

    <!--- <cfrethrow/> --->
    <cfset getFileInfo("/mnt/NAS_Backup/Thomas2/Music/-Classical/Classical Music Top 100 (1996)/Albinoni - Adagio In Sol Minore.mp3") />
</cfcatch>
</cftry> --->

<!--- sudo mount -t cifs -o username=admin //192.168.1.84/home/Backup /mnt/NAS_Backup/ --->
<!--- "/mnt/NAS_Backup/Thomas2/Music/-Classical/Classical Music Top 100 (1996)/Albinoni - Adagio In Sol Minore.mp3" --->