<!--- APPLICATION.CFC

    <cfset this.defaultdatasource = {
        class: "org.sqlite.JDBC",
        connectionString: "jdbc:sqlite:#this.root#dfa8c46a-29b3-4a1f-947e-0bdd385380bb/RecipeDB.sdb",
        timezone: "CET",
        custom: {useUnicode: true, characterEncoding: 'UTF-8', Version: 3},
        blob: true,
        clob: true,
        validate: true
    } />
    
--->

<!---
    LESSONS LEARNED:
    1:  cfquery cannot parse SQLite (date)time-stamps... So it appears we have to use VARCHAR for datetime columns
        We can however still use "DEFAULT (datetime('now'))" for those columns to set default dates
        Curiously if you do "SELECT datetime(ColumnName)" it works, but it comes back as a string, and not a date object. 
    2: The datetime('now') of SQLite is "dd-mm-yyyy HH:nn:ss", without the usual ODBC {ts ''} format. It can luckily still be parsed into a date by Lucee
    3: Any methods that operate on dates in the db and accept them as arguments should have param-type DATE so we don't have to worry about dodgy strings
    4: BLOB's can be added via cfquery but when read the data comes back as string, which is useless.. Seems you need to have the column as BLOB but still convert to HEX or Base64 when storing it.
    5:  cfquery does not always play nice with prepared statements which gives you obscure query errors along the lines of "SQLite does not support this operation".
        To deal with that, use the params-attribute of the cfquery tag to coerce cfquery into making better prepared statements. Oh, and use the simple struct- or array-format!
--->

<cfdump var=#application# label="APPLICATION SCOPE" />
<!--- <cfset images = new ImageManager() /> --->

<cfset fileContent = fileReadBinary(application.rootDir & "DSC_0814.JPG") />
<!--- <cfdump var=#fileContent# abort="true" /> --->
<!--- <cfset newID = images.add(fileContent, "image/jpeg", "me.jpg", 2, 1) /> --->

<!--- <cfimage name="NewRecipeImage" action="read" source=#fileContent# />
<cfset imageSetAntialiasing(NewRecipeImage, "on") />
<cfset imageScaleTofit(NewRecipeImage, 450, 300, "bicubic") />

<cfloop from=1 to=1 index="CurrentIndex" >

    // NOTE: 'WHERE X IN' statements don't work with integer type queryparams. It won't accept an array of numbers, saying it can't cast it to a string
    <cfset QueryParams = [
        CurrentIndex,
        "image/jpeg",
        "random.jpg",
        ToBase64(ImageGetBlob(NewRecipeImage)),
        <!--- createODBCDateTime(dateConvert("Local2UTC", now())), --->
        <!--- createODBCDateTime(dateConvert("Local2UTC", now())), --->
        1
    ] />

    <cfquery result="Test" params=#QueryParams# >
        INSERT INTO RecipeImages (BelongsToRecipe, MimeType, OriginalName, Base64Content<!---, DateTimeCreated, DateTimeLastModified--->, ModifiedByUser)
        VALUES (?,?,?,?,?);
    </cfquery>

</cfloop>

<cfdump var=#toNumeric(Test.GeneratedKey)# /> --->

<!--- <cfdbinfo name="dbinfo" type="Columns" table="RecipeImages" />
<cfdump var=#dbinfo# />

<cfset NormalizedDateTime = createODBCDateTime(dateConvert("Local2UTC", now())) />
<cfset LocalDateTime = DateConvert("UTC2Local", NormalizedDateTime) />

<cfdump var=#NormalizedDateTime# />
<cfdump var=#LocalDateTime# />
<cfdump var=#DateTimeFormat(LocalDateTime, "dd-mm-yyyy HH:nn:ss")# /> --->

<!--- <cfdump var=#ParseDateTime("2021-01-06 21:46:43")# /> --->

<cfquery name="TestImage" >
    SELECT * FROM RecipeImages
    WHERE ImageID = 1
</cfquery>

<cfdump var=#TestImage# />

<!--- <cfset fileWrite(application.rootDir & "me2.jpg", toBinary(TestImage.Base64Content)) /> --->
<!--- <cfcontent type="image/*" variable=#Test.Base64Content# reset="true" > --->
<p>Done!</p>