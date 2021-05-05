<cfcomponent modifier="final" persistent="true" output="false" accessors="false" >

    <cfproperty name="MaxSize"          type="numeric"  getter="false" setter="false" />
    <cfproperty name="CacheFolder"      type="string"   getter="false" setter="false" />
    <cfproperty name="RemovePolicy"     type="numeric"  getter="false" setter="false" />
    <cfproperty name="CacheManifest"    type="struct"   getter="false" setter="false" />
    <cfproperty name="HashAlgorithm"    type="string"   getter="false" setter="false" />
    <cfproperty name="CacheSize"        type="numeric"  getter="false" setter="false" />
    <cfproperty name="Logger"           type="ILogger"  getter="false" setter="false" />

    <cfset variables.REMOVAL_POLICIES = {
        "LIFO": 0, // Last in, first out (based on the lastDateModified value)
        "SMALLEST": 1,
        "BIGGEST": 2
    } />

    <cfset variables.ValidHashes = "MD5,SHA,SHA-256,SHA-384,SHA-512" />

    <cffunction access="public" name="init" returntype="WAVCache" output="false" >
        <cfargument name="cacheFolder" type="string" required="true" default="" hint="The folder in which the WAV files will be stored" />
        <cfargument name="fileManifest" type="array" required="true" default="" hint="An array of absolute filepaths to the music files the cache will be accessing" />
        <cfargument name="maxSize" type="numeric" required="false" default="0" hint="The max size that will be used by the cache. Optional, defaults to 200MB. NOTE: If you pass a size below 200MB it will be set to 200MB" />
        <cfargument name="removePolicy" type="string" required="false" default="LIFO" hint="The policy used for removing files when the cache limit is hit. Valid values are LIFO, SMALLEST, BIGGEST. Optional, defaults to LIFO" />
        <cfargument name="purge" type="boolean" required="false" default="false" hint="Whether the purge any existing WAV-files from the cache folder first. Optional, defaults to false" />
        <cfargument name="hashAlgorithm" type="string" required="false" default="SHA-256" hint="Which algorithm to use for hashing the files in 'fileManifest' for storage in the internal cache manifest" />
        <cfargument name="logger" type="ILogger" required="true" hint="" />

        <cfscript>

        if (!directoryExists(arguments.cacheFolder))
            throw(message="Error instantiating WAVCache", detail="Argument 'cacheFolder' is not a folder or does not exist");

        if (listFind(structKeyList(variables.REMOVAL_POLICIES), arguments.removePolicy) == 0)
            throw(message="Error instantiating WAVCache", detail="Argument 'removePolicy' is not valid: #arguments.removePolicy# | Valid values are: #structKeyList(variables.REMOVAL_POLICIES)#");

        if (listFind(variables.ValidHashes, arguments.hashAlgorithm) == 0)
            throw(message="Error instantiating WAVCache", detail="Argument 'hashAlgorithm' isn't valid: #arguments.hashAlgorithm# | Valid values are: #variables.ValidHashes#");

        variables.CacheFolder = arguments.cacheFolder;
        variables.RemovePolicy = variables.REMOVAL_POLICIES[arguments.removePolicy];
        variables.CacheSize = 0;
        variables.Logger = arguments.logger;

        var MinimumSize = 200 * 1024 * 1024;
        variables.MaxSize = arguments.maxSize < MinimumSize ? arguments.maxSize : MinimumSize;

        var CacheFolderContents = directorylist(
            path=arguments.cacheFolder,
            recurse=false,
            listInfo="query",
            type="file",
            filter="*.wav"
        );

        if (arguments.purge)
            for(var CurrentFileRow in CacheFolderContents)
                fileDelete("#CurrentFileRow.directory#/#CurrentFileRow.name#");

        CreateManifest(arguments.fileManifest, arguments.purge ? null : CacheFolderContents);

        return this;
        </cfscript>
    </cffunction>

    <cffunction access="public" name="Get" returntype="struct" output="false" >
        <cfargument name="ID" type="string" required="true" default="" />

        <cfscript>
            if (!structKeyExists(variables.CacheManifest, arguments.ID)) return "";
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

    <cffunction access="private" name="CreateManifest" returntype="void" output="false" >
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

        if (arguments.cacheFolderContents == null) return;

        for(var CurrentFileRow in arguments.cacheFolderContents)
        {
            var FileID = listFirst(CurrentFileRow.name, ".");

            if (!structKeyExists(variables.CacheManifest, FileID))
            {
                fileDelete("#CurrentFileRow.directory#/#CurrentFileRow.name#");
                continue;
            }

            variables.CacheFolder[FileID].Size = CurrentFileRow.size;
            variables.CacheFolder[FileID].DateTimeCreated = CurrentFileRow.dateLastModified;
            variables.CacheFolder[FileID].InCache = true;

            variables.CacheSize = variables.CacheSize + CurrentFileRow.size;
        }
        </cfscript>
    </cffunction>

    <cffunction access="private" name="TrimCache" returntype="void" output="false" >
        <cfscript>

        variables.CacheSize = variables.CacheSize - FileInfo.size;

        </cfscript>
    </cffunction>

    <cffunction access="private" name="DecodeAndAdd" returntype="boolean" output="false" >
        <cfargument name="ID" type="string" required="true" default="" />
        <cfscript>

        var FilePath = variables.CacheManifest[arguments.ID].Path;

        try {
            cfexecute(
                name="ffmpeg",
                arguments="-i -v error ""#FilePath#"" ""#variables.CacheFolder#/#arguments.ID#.wav""",
                timeout="5",
                terminateOnTimeout="true"
            );
        }
        catch("lucee.runtime.exp.ApplicationException" error)
        {
            return false;
        }

        try {
            var FileInfo = getFileInfo("#variables.CacheFolder#/#arguments.ID#.wav");
        }
        catch(any error)
        {
            return false;
        }

        variables.CacheFolder[arguments.ID].Size = FileInfo.size;
        variables.CacheFolder[arguments.ID].DateTimeCreated = createODBCDateTime(now());
        variables.CacheFolder[arguments.ID].InCache = true;

        variables.CacheSize = variables.CacheSize + FileInfo.size;

        if (variables.CacheSize > variables.MaxSize)
            runAsync(TrimCache).get();

        return true;
        </cfscript>
    </cffunction>
</cfcomponent>