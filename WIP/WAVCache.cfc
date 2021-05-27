<cfcomponent modifier="final" persistent="true" output="true" accessors="false" >

    <cfproperty name="MaxSize"          type="numeric"  getter="false" setter="false" />
    <cfproperty name="CacheFolder"      type="string"   getter="false" setter="false" />
    <cfproperty name="RemovePolicy"     type="numeric"  getter="false" setter="false" />
    <cfproperty name="CacheManifest"    type="struct"   getter="false" setter="false" />
    <cfproperty name="HashAlgorithm"    type="string"   getter="false" setter="false" />
    <cfproperty name="CacheSize"        type="numeric"  getter="false" setter="false" />
    <cfproperty name="Logger"           type="ILogger"  getter="false" setter="false" />

    <!---
        CacheManifest = Dictionary<string, object>
        where "string" = HASH
        where "object" = {
            Size: int
            DateTimeCreated: string
            Path: string
            InCache: bool
        }
    --->

    <cfset variables.REMOVAL_POLICIES = {
        "LIFO": 0, // Last in, first out (based on the lastDateModified value)
        "SMALLEST": 1,
        "BIGGEST": 2
    } />

    <cfset variables.ValidHashes = "MD5,SHA,SHA-256,SHA-384,SHA-512" />
    <cfset variables.CacheBeingTrimmed = false />
    <cfset variables.sanitizeFolderPath = function(required string path) {
        var FirstPass = reReplace(arguments.path, "\\", "/", "ALL"); // Change all backslashes to forward
        var SecondPass = reReplace(FirstPass, "/{2,}", "/", "ALL"); // Remove all consecutive forward slashes past 1
        return reReplace(SecondPass, "/$", ""); // Remove trailing slash
    } />

    <cffunction access="public" name="init" returntype="WAVCache" output="true" >
        <cfargument name="cacheFolder" type="string" required="true" default="" hint="The folder in which the WAV files will be stored" />
        <cfargument name="fileManifest" type="array" required="true" default="" hint="An array of absolute filepaths to the music files the cache will be accessing. These will be hashed and this hash becomes the ID for this file" />
        <cfargument name="maxSize" type="numeric" required="false" default="0" hint="The max size that will be used by the cache. Optional, defaults to 200MB. NOTE: If you pass a size below 200MB it will be set to 200MB" />
        <cfargument name="removePolicy" type="string" required="false" default="LIFO" hint="The policy used for removing files when the cache limit is hit. Valid values are LIFO, SMALLEST, BIGGEST. Optional, defaults to LIFO" />
        <cfargument name="purge" type="boolean" required="false" default="false" hint="Whether the purge any existing WAV-files from the cache folder first. Optional, defaults to false" />
        <cfargument name="hashAlgorithm" type="string" required="false" default="SHA" hint="Which algorithm to use for hashing the files in 'fileManifest' for storage in the internal cache manifest" />
        <cfargument name="logger" type="ILogger" required="true" hint="" />

        <cfscript>

        if (!directoryExists(arguments.cacheFolder))
            throw(message="Error instantiating WAVCache", detail="Argument 'cacheFolder' is not a folder or does not exist");

        if (listFind(structKeyList(variables.REMOVAL_POLICIES), arguments.removePolicy) == 0)
            throw(message="Error instantiating WAVCache", detail="Argument 'removePolicy' is not valid: #arguments.removePolicy# | Valid values are: #structKeyList(variables.REMOVAL_POLICIES)#");

        if (listFind(variables.ValidHashes, arguments.hashAlgorithm) == 0)
            throw(message="Error instantiating WAVCache", detail="Argument 'hashAlgorithm' isn't valid: #arguments.hashAlgorithm# | Valid values are: #variables.ValidHashes#");

        variables.HashAlgorithm = arguments.hashAlgorithm;
        variables.CacheFolder = sanitizeFolderPath(arguments.cacheFolder);
        variables.RemovePolicy = variables.REMOVAL_POLICIES[arguments.removePolicy];
        variables.CacheSize = 0;
        variables.Logger = arguments.logger;

        var MinimumSize = 200 * 1024 * 1024;
        variables.MaxSize = arguments.maxSize < MinimumSize ? arguments.maxSize : MinimumSize;

        variables.Logger.Information("Max cache size set to: " & variables.MaxSize & " bytes", getFunctionCalledName());
        variables.Logger.Information("Hash algorithm set to: " & variables.HashAlgorithm, getFunctionCalledName());
        variables.Logger.Information("File manifest contains #arguments.fileManifest.len()# files", getFunctionCalledName());

        var CacheFolderContents = directorylist(
            path=arguments.cacheFolder,
            recurse=false,
            listInfo="query",
            type="file",
            filter="*.wav"
        );

        variables.Logger.Information("Found #CacheFolderContents.RecordCount# existing WAV-files in cache", getFunctionCalledName());
        if (arguments.purge)
            variables.Logger.Information("Purging existing files", getFunctionCalledName());

        for(var CurrentRow in CacheFolderContents)
        {
            if (arguments.purge)
                fileDelete("#CurrentFileRow.directory#/#CurrentFileRow.name#");
            else
                variables.CacheSize = variables.CacheSize + CurrentRow.Size;
        }

        variables.Logger.Information("Size of cache is: " & variables.CacheSize, getFunctionCalledName());
        CreateManifest(arguments.fileManifest, arguments.purge ? null : CacheFolderContents);

        return this;
        </cfscript>
    </cffunction>

    <cffunction access="public" name="Get" returntype="struct" output="true" >
        <cfargument name="ID" type="string" required="true" hint="The ID of the file in the form of a hash" />

        <cfscript>
            if (!structKeyExists(variables.CacheManifest, arguments.ID))
            {
                variables.Logger.Warning("File with ID #arguments.ID# is not in the manifest", getFunctionCalledName());
                return {"FilePath": "", "Size": 0};
            }

            var FileData = variables.CacheManifest[arguments.ID];

            if (!FileData.InCache)
            {
                if (!DecodeAndAdd(arguments.ID))
                    return {"FilePath": "", "Size": 0};
            };

            return {
                "FilePath": "#variables.CacheFolder#/#arguments.ID#.wav",
                "Size": FileData.Size,
            };
        </cfscript>
    </cffunction>

    <!--- PRIVATE --->

    <cffunction access="private" name="CreateManifest" returntype="void" output="true" >
        <cfargument name="fileManifest" type="array" required="true" default="" />
        <cfargument name="cacheFolderContents" type="query" required="true" default="" />

        <cfscript>
        for(var CurrentFile in arguments.fileManifest)
        {
            variables.CacheManifest[hash(CurrentFile, variables.HashAlgorithm)] = {
                "Size": 0,
                "DateTimeCreated": "",
                "Path": CurrentFile,
                "InCache": false
            }
        }

        if (isNull(arguments.cacheFolderContents)) return;

        for(var CurrentFileRow in arguments.cacheFolderContents)
        {
            var FileID = listFirst(CurrentFileRow.Name, ".");

            if (!structKeyExists(variables.CacheManifest, FileID))
            {
                variables.Logger.Warning("Removing file from cache not present in file manifest: #CurrentFileRow.Name#", getFunctionCalledName());
                fileDelete("#CurrentFileRow.directory#/#CurrentFileRow.Name#");

                continue;
            }

            variables.CacheManifest[FileID] = {
                "Size": CurrentFileRow.Size,
                "DateTimeCreated": CurrentFileRow.DateLastModified,
                "InCache": true
            };

            variables.CacheSize = variables.CacheSize + CurrentFileRow.Size;
        }
        </cfscript>
    </cffunction>

    <cffunction access="private" name="TrimCache" returntype="void" output="true" >
        <cfscript>
        variables.CacheBeingTrimmed = true;
        variables.Logger.Information("Trimming the cache", getFunctionCalledName());
        // LIFO
        var SortBy = "DateLastModified DESC";

        if (variables.RemovePolicy == 1)
            SortBy = "Size ASC";
        else if (variables.RemovePolicy == 2)
            SortBy = "Size DESC";

        var EntryToRemove = directorylist(
            path=variables.CacheFolder,
            recurse=false,
            listInfo="query",
            type="file",
            filter="*.wav",
            sort=#SortBy#
        ).getRow(1);

        variables.Logger.Information("Removing file: #EntryToRemove.Name#, #EntryToRemove.Size# bytes", getFunctionCalledName());

        fileDelete("#variables.CacheFolder#/#EntryToRemove.Name#");
        variables.CacheSize = variables.CacheSize - EntryToRemove.Size;
        variables.CacheManifest[listFirst(EntryToRemove.Name, ".")].InCache = false;

        variables.Logger.Information("Cache size after trim: #variables.CacheSize# bytes", getFunctionCalledName());

        if (variables.CacheSize > variables.MaxSize)
            TrimCache();
        else
            variables.CacheBeingTrimmed = false;
        </cfscript>
    </cffunction>

    <cffunction access="private" name="DecodeAndAdd" returntype="boolean" output="true" >
        <cfargument name="ID" type="string" required="true" default="" />
        <cfscript>

        var FilePath = variables.CacheManifest[arguments.ID].Path;
        var FFMpegArguments = "-i ""#FilePath#"" ""#variables.CacheFolder#/#arguments.ID#.wav"" -v error";

        try {
            // cfexecute(
            //     name="ffmpeg",
            //     arguments=#FFMpegArguments#,
            //     timeout="5",
            //     terminateOnTimeout="true"
            // );
            cfexecute(
                name="C:\MediaToolkit\ffmpeg.exe",
                arguments=#FFMpegArguments#,
                timeout="5",
                terminateOnTimeout="true"
            );
        }
        catch("lucee.runtime.exp.ApplicationException" error)
        {
            variables.Logger.Error("Error when attempting to decode file with ID #arguments.ID#, using these arguments: #FFMpegArguments#", getFunctionCalledName());
            variables.Logger.Error("#error.Message# - #error.Detail#", getFunctionCalledName());

            return false;
        }

        try {
            var FileInfo = getFileInfo("#variables.CacheFolder#/#arguments.ID#.wav");
        }
        catch(any error)
        {
            variables.Logger.Error("Error when attempting to get file info after decoding (#arguments.ID# | #variables.CacheFolder#/#arguments.ID#.wav)", getFunctionCalledName());
            return false;
        }

        variables.CacheManifest[arguments.ID] = {
            "Size": FileInfo.size,
            "DateTimeCreated": createODBCDateTime(now()),
            "InCache": true
        };

        var Entry = variables.CacheManifest[arguments.ID];
        variables.CacheSize = variables.CacheSize + FileInfo.size;

        variables.Logger.Information("Decoded and added new entry: ID: #arguments.ID# | Size: #Entry.Size# | DateTimeCreated: #Entry.DateTimeCreated# | InCache: #Entry.InCache#", getFunctionCalledName());
        variables.Logger.Information("Cache size is now: #variables.CacheSize# bytes", getFunctionCalledName());

        if (!variables.CacheBeingTrimmed && variables.CacheSize > variables.MaxSize)
            runAsync(TrimCache);

        return true;
        </cfscript>
    </cffunction>
</cfcomponent>