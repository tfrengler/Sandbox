<cfoutput>

<cfset oCandidates = createObject("component", "CFCs.Candidates") />
<cfset oUtils = createObject("component", "CFCs.Utils") />
<cfset oReporter = createObject("component", "Tests.Selenium.Components.Reporter").init(SetDefaultFileDestination=false) />

<cfset GetTestQueryStartTime = getTickCount() />

<cfset qTestData = oCandidates.applyFilter(
	FilterID=134593,
	Object="Candidates",
	Archive=0,
	BuildXML=0,
	UserID=207407,
	DomeinCode="COP1",
<!--- 	Maxrows=XXX,	--->
	Language="dk"
) />

<cfset oReporter.log("Time taken to fetch query for our test: #oReporter.getElapsedTime( StartTime=GetTestQueryStartTime)# seconds") />

<cfset QueryLoopCounter = 0 />
<cfset ThreadWatchThrottleList = "" />
<cfset MainThreadList = "" />
<cfset MaxThreads = 10 />

<!--- 
	At first I used java.util.concurrent.ConcurrentHashMap using method putIfAbsent() to insert the query data into it at 
	the end of the thread, but although the keys were there, the values were always undefined. To my great surprise I 
	discovered that CF's structs are threadsafe when it comes to insert data, at least when using structInsert. It's possible 
	that structInsert does the locking so that if you use <cfset struct[Key] = value /> it might go wrong. It didn't test that.
 --->
<cfset ReturnData = structNew() />

<cfset ThreadTestStartTime = getTickCount() />

<cfloop query="#qTestData#" >

	<cfset QueryLoopCounter = (QueryLoopCounter + 1) />

	<cfset ThreadWatchThrottleList = listAppend(ThreadWatchThrottleList, "QueryRowThread_#QueryLoopCounter#") />
	<cfset MainThreadList = listAppend(MainThreadList, "QueryRowThread_#QueryLoopCounter#") />

	<!--- 
		Spawning a thread per query row to work on that row's data and put the manipulated data into our struct.

		Unlike functions, all variables declared inside a cfthread are automatically only scoped to that thread. It's not even possible to declare NEW variables outside the thread
		although we can manipulate or read them from within the thread. That also means that all local variables are killed once the thread is done running so keep that in mind!

		There's a second scope, the thread-scope, which will persist after the thread is done running and which can also be accessed WHILE it's running. Outside of the thread
		you can access it through cfthread[NameOfTheThread], the name being the name-attribute you pass to <cfthread> obviously. The thread-scope for each thread already
		has a number of members by default, such as Status, Name, Error etc.

		Anything the thread outputs (including throwing errors) will not be shown in the calling page. You have to go check for it and grab it yourself. Errors that stop the thread
		will appear in the Error-property of the thread-scope. You might also want to use try/catch inside the thread instead and some form of logging. The Error-property of the
		thread will NOT be populated and its status will read as COMPLETED if you catch the error yourself!

		As a continuation of the above: any visual/HTML output (from cfoutput or otherwise) will be stored in the Output-property of the thread-scope. You can't use cfflush inside
		the thread because it has to wait to finish before it dumps the buffer into the Output-property.

		You can pass variables with data into the thread using custom named attributes in the <cfthread>-tag. These variables, including any references, will all be deep copied
		so there's nothing connection back to the original variable, thus making them threadsafe. Keep that in mind before you pass in big and heavy, or just complex, objects.

		Of course keep thread-safety in mind whenever you decide to either read or write to variables outside of the thread!
	 --->
	<cfthread 
		action="run"
		name="QueryRowThread_#QueryLoopCounter#"
		columnList="#qTestData.columnList#"
		queryRowCount=#QueryLoopCounter#
		queryRow="#qTestData.getRow(QueryLoopCounter)#" >

		<cftry>
			<cfset CurrentQueryRow = structNew() />

			<cfloop list="#attributes.columnList#" index="sQueryColumnName" >

				<cfset CurrentColumData = attributes.queryRow[sQueryColumnName] />
				<cfset CurrentColumNewData = "" />

				<cfif len(CurrentColumData) GT 0 >
					<cfset CurrentColumNewData = ReReplaceNoCase(CurrentColumData, "[^0-9,]", "", "ALL") />
					<cfset CurrentColumNewData = oUtils.cleanHTML(CurrentColumNewData, "") />
					<cfset CurrentColumNewData = REReplace(CurrentColumNewData,"\t|\n|\r", "", "ALL") >
					<cfset CurrentColumNewData = REReplace(CurrentColumNewData, "&nbsp;|nbsp;|&nbsp", "", "all") />
					<cfset CurrentColumNewData = "<span title='#HTMLEditFormat(CurrentColumData)#' >#HTMLEditFormat(CurrentColumData)#</span>" />
				<cfelse>
					<cfset CurrentColumNewData = "&nbsp;" />
				</cfif> 

				<cfset structInsert(CurrentQueryRow, sQueryColumnName, CurrentColumNewData) />

			</cfloop>

			<cfset structInsert(ReturnData, attributes.queryRow["LidID"], CurrentQueryRow) />
		<cfcatch>
			<cfset thread.catch = cfcatch />
		</cfcatch>
		</cftry>

	</cfthread>

	<!--- 
		This is a thread throttle. Without it CF will keep spawning threads. The CF admin has a setting for max concurrent threads. The rest will be queued but there's a limit
		to the queue as well. In my case it was 5000 and with a recordset of 9100+ I hit that quite quickly. This ensures that 10 threads max are running at any given time,
		then it waits for them to finish, clears the list and lets 10 more threads spawn. There might be a clever way to not wait for all the threads to finish before allowing a new
		batch but this was the easiest, simplest way I could think of straight off the bat.
	 --->
	<cfif listLen(ThreadWatchThrottleList) EQ MaxThreads >
		<cfthread action="join" name="#ThreadWatchThrottleList#" timeout="10000" />
		<cfset ThreadWatchThrottleList = "" />
	</cfif>
</cfloop>
r
<!---  	Similar to the thread throttle above, this join-action basically watches a comma-delimited list of thread names, and won't proceed with processing past this tag, until they are all 
	completed OR the timeout is hit. Once the timeout is reached it continues processing past the <cfthread>-tag regardless of status of the threads it watches. --->
<cfthread action="join" name="#MainThreadList#" timeout="120000" />

<!--- 
	Purely for debugging purposes, and to show how we can access the threads after they've all executed (although we can do that as they run as well).
	We simply loop through them all, check for the existence of the Error-property, and if it's there we dump the info on the screen. And abort, because in
	my little test example here if one thread failed, they usually all failed with the same error, so no point outputting them all.
--->
<cfloop list="#MainThreadList#" index="CurrentThreadName" >
	<cfset CurrentThread = cfthread[CurrentThreadName] />

	<cfif structKeyExists(CurrentThread, "Error") AND isStruct(CurrentThread.Error) >

		<p>#CurrentThreadName#:<br/>#CurrentThread.Error.Message#</p>
		<cfabort/>

	<cfelseif structKeyExists(CurrentThread, "catch") >

		<cfthrow object="#CurrentThread.catch#" />
		<cfabort/>

	</cfif>
</cfloop>

<cfset oReporter.log("SUCCESS!!! Time taken for our threaded query process: #oReporter.getElapsedTime( StartTime=ThreadTestStartTime)# seconds") />
<cfset oReporter.log("Processed #qTestData.RecordCount# records in our test query, and we have #structCount(ReturnData)# in our structure") />

<!--- The dump at the end usually takes the longest, so leave that out if you're testing performance. In my case it processed a 9100+ recordset in 2.5 seconds average. Not bad! --->
<!--- <cfdump var="#ReturnData#" /> --->

</cfoutput>