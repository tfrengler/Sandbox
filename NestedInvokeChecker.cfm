<cfprocessingdirective pageencoding="utf-8" />
<!DOCTYPE html>

<html>

	<head>
		<title>Invokes nested in loops</title>
		<meta content="text/html; charset=utf-8" http-equiv="Content-Type" />
		<meta name="author" content="Thomas Frengler" />

		<style>
			#FormElementsContainer {
				margin-left: 1em;
				padding: 1em;
				border-style: solid;
				border-width: 1px;
				display: inline-block;
				background-color: lightgrey;
			}

			.bad {
				color: white;
				background-color: red;
			}

			.good {
				color: white;
				background-color: darkgreen;
			}

			input[type='text'] {
				width: 100%;
			}

			h1 {
				text-align: center;
				background-color: #3d5c5c;
				color: white;
			}
		</style>
	</head>

	<body>

		<cffunction name="extractLoop" access="public" returntype="struct" hint="Can handle nested loops as well, which is why it's so complicated" >
			<cfargument name="StartPosition" type="numeric" required="true" />
			<cfargument name="StringContainingLoop" type="string" required="true" />

			<cfset var ReturnData = {
				StartPos: arguments.StartPosition,
				EndPos: 0,
				Length: 0,
				Content: "",
				HasNested: false,
				IsNested: false
			} />

			<!--- You may ask: why start 5 characters ahead of the loop position? Because we don't want to count the loop that we are trying to extract --->
			<cfset var LoopStartingPositions = reFindNoCase("<cfloop\b", arguments.StringContainingLoop, (arguments.StartPosition + 5), false, "all") />
			<cfset var LoopEndingPositions = reFindNoCase("</cfloop>", arguments.StringContainingLoop, arguments.StartPosition, false, "all") />

			<cfif isArray(LoopEndingPositions) IS false >
				<cfthrow message="Error when extracting loop" detail="There's no <cfloop>-endtags after this start position (#arguments.StartPosition#). This indicates a possible syntax error." />
			</cfif>

			<!--- reFindNoCase returns an int with a value of 0 is nothing is found --->
			<cfif isArray(LoopStartingPositions) IS false >
				<cfset LoopStartingPositions = arrayNew(1) />
			</cfif>
		
			<cfset var LoopStartTagBeforeEndTagHits = 0 />
			<cfset var LoopStartTagsBeforeEndTagTracker = "" />
			<cfset var LoopEndTagsCounter = 0 />
			<cfset var LoopStartTagsBeforeEndTagCompare = 0 />
			<cfset var ExtractedLoop = "" />
			<cfset var EndTagPosition = 0 />
			<cfset var StartTagPosition = 0 />

			<!--- Loop through all the end tags we found --->
			<cfloop array=#LoopEndingPositions# index="EndTagPosition" >

				<!--- 
					Increment a counter to keep track of how many end tags we are currently expecting. 
					This will be used to compare against the amount of start tags we find later.
				--->
				<cfset LoopEndTagsCounter++ />
				<cfset LoopStartTagsBeforeEndTagCompare = LoopStartTagBeforeEndTagHits />

				<!--- For each end tag we loop through all the start tags (If there are any start tags that is) --->
				<cfif arrayLen(LoopStartingPositions) GT 0 >
					<cfloop array=#LoopStartingPositions# index="StartTagPosition" >

						<!--- 
							If the start tag starts before the end tag, we know it's the begnning of a nested loop.
							We therefore increment a counter of start tags and also add the position to a track so that
							don't count that tag again on the next check of the next end tag.
						--->
						<cfif StartTagPosition LT EndTagPosition AND listFind(LoopStartTagsBeforeEndTagTracker, StartTagPosition) IS 0 >

							<cfset LoopStartTagBeforeEndTagHits++ />
							<cfset LoopStartTagsBeforeEndTagTracker = listAppend(LoopStartTagsBeforeEndTagTracker, StartTagPosition) />

						</cfif>

					</cfloop>
				</cfif>

				<!--- If the amount of start tags didn't increase at all or didn't increase compared to before this might be our end tag --->
				<cfif LoopStartTagBeforeEndTagHits IS 0 OR LoopStartTagBeforeEndTagHits IS LoopStartTagsBeforeEndTagCompare >

					<!--- 
						If we have even more nested loops inside the nested loop we can't just rely on the logic above.
						This end tag could be closing one of the nested tags which means there'd be no start tags between
						this and the previous end tag. So whether we have an equal amount of start and end tags. If we do
						then this is our end tag.
					--->
					<cfif LoopEndTagsCounter IS (LoopStartTagBeforeEndTagHits + 1) >

						<cfset ExtractedLoop = mid(
							arguments.StringContainingLoop,
							arguments.StartPosition,
							EndTagPosition - arguments.StartPosition + 9 <!--- This is for extracting the whole cfloop-endtag since EndTagPosition is the start of the tag --->
						) />
						<cfbreak/>

					</cfif>

				</cfif>

			</cfloop>

			<!--- +1 because LoopStartingPositions doesn't have the start tag of the loop we are extracting --->
			<cfif arrayLen(LoopEndingPositions) GT (arrayLen(LoopStartingPositions) + 1) >
				<cfset ReturnData.IsNested = true />
			</cfif>

			<cfif LoopStartTagBeforeEndTagHits GT 0 >
				<cfset ReturnData.HasNested = true />
			</cfif>

			<cfset ReturnData.EndPos = (arguments.StartPosition + len(ExtractedLoop) - 1) />
			<cfset ReturnData.Length = len(ExtractedLoop) />
			<cfset ReturnData.Content = ExtractedLoop />

			<cfreturn ReturnData />
		</cffunction>

		<cfoutput>

				<cfset ProcessFile = false />

				<h1>FIND CFINVOKES NESTED IN LOOPS</h1>
				<hr/>

				<form name="ScanFileFORM" action="NestedInvokeChecker.cfm" enctype="application/x-www-form-urlencoded" method="post" >
					<div id="FormElementsContainer">

						<p>
							<div>FILE TO SCAN:</div>
							<input type="text" name="FileToScan" value=<cfif isDefined("FORM.FileToScan") AND len(FORM.FileToScan) GT 0 >"#FORM.FileToScan#"<cfelse>""</cfif> placeholder="absolute path" />
							<br/><br/>
							<input id="SubmitButton" type="submit" value="SCAN FILE" />
						</p>

						<span>
							Use this tool to scan cfc- or cfm-files for cfinvokes nested inside cfloop- or cfoutput-query tags. There are some limitations:
							<ul>
								<li>It can't handle cfoutput's nested inside cfoutputs, but that relatively rare.</li>
								<li>It doesn't distinguish combinations of cfoutput's nested inside cfloops or the other way around, so you may get the same cfinvoke reported mutiple times</li>
								<li>The line numbers are found by converting the file contents to a list, using CR as a delimiter. So that may not work correctly on Mac or Unix systems.</li>
								<li>Due to CF regex not supporting lookbehind it can't reliably exclude commented out code.</li>
								<li>Crazy/dumb/non-standard variations in syntax. Such as not doing a newline or carriage return after the opening cfinvoke-tag before doing a cfinvokeargument.</li>
							</ul>
						</span>
					</div>
				</form>

				<cfif structIsEmpty(FORM) IS false >

					<cfif len(FORM.FileToScan) IS 0 >
						<h3 class="bad" >You didn't put in a path to file</h3>
					</cfif>

					<cfif fileExists(FORM.FileToScan) IS false >
						<h3 class="bad" >The file you pointed to doesn't seem to exist</h3>
					<cfelse>
						<cfset ProcessFile = true />
					</cfif>

				</cfif>

				<cfif ProcessFile >

					<cfset NoLoops = false />
					<cfset NoOutputs = false />

					<cfset FileToParse = FORM.FileToScan />

					<cffile action="read" file=#FileToParse# variable="FileContents" />

					<cfset LoopStartTagPositions = reFindNoCase("<cfloop\b", FileContents, 1, false, "all") />
					<cfset CfouputQueryPattern = "<cfoutput(?=.+?(?=query=))[\S\s]+?</cfoutput>" />
					<cfset InvokesFound = arrayNew(1) />

					<cfif isArray(LoopStartTagPositions) AND arrayLen(LoopStartTagPositions) GT 1 >

						<cfloop array=#LoopStartTagPositions# index="LoopPosition" >

							<cfset LoopExtraction = extractLoop(StartPosition=LoopPosition, StringContainingLoop=FileContents) />

							<cfif LoopExtraction.isNested IS true >
								<cfcontinue/>
							<cfelse>
								<cfset InvokeMatch = reFindNoCase("<cfinvoke\b", LoopExtraction.Content, 1, false, "all") />
							</cfif>

							<cfif isArray(InvokeMatch) >
								<cfset structInsert(LoopExtraction, "InvokeMatches", InvokeMatch) />
								<cfset arrayAppend(InvokesFound, LoopExtraction) />
							</cfif>
						</cfloop>

					<cfelse>
						<h3 class="good" >No CFLOOP's to check</h3>
						<cfset NoLoops = true />
					</cfif>

					<cfif arrayLen(InvokesFound) GT 0 >
						<h3 class="bad" >Invokes inside CFLOOP found:</h3>

						<cfloop array=#InvokesFound# index="LoopExtract" >

							<cfset LoopLineNumber = mid( FileContents, 1, LoopExtract.StartPos ) />
							<cfset LoopLineNumber = listLen(LoopLineNumber, chr(13)) />

							<ul>

								<li>inside a cfloop <cfif LoopExtract.HasNested IS true>(<u>possibly inside a nested loop</u>)</cfif> starting on line <b>#LoopLineNumber#:</b></li>
								<br/>

								<cfloop array=#LoopExtract.InvokeMatches# index="InvokePosition" >

									<ul>
										<cfset InvokeLineNumber = mid( FileContents, 1, (LoopExtract.StartPos + InvokePosition - 1) ) />
										<cfset InvokeLineNumber = listLen(InvokeLineNumber, chr(13)) />
										<li>on line: <u>#InvokeLineNumber#</u></li>
									</ul>

								</cfloop>

							</ul>

						</cfloop>
					<cfelse>
						<cfif NoLoops IS false >
							<h3 class="good" >NO invokes found inside CFLOOP</h3>
						</cfif>
					</cfif>

					<cfset CfoutputMatches = reFindNoCase(CfouputQueryPattern, FileContents, 1, true, "all") />
					<cfset InvokesFound = arrayNew(1) />

					<!--- Loop through all cfoutputs and check for cfinvokes --->
					<cfif isArray(CfoutputMatches) AND arrayLen(CfoutputMatches) GT 1 >

						<cfloop array=#CfoutputMatches# index="CurrentMatch" >
							<cfset CfinvokeMatch = reFindNoCase("<cfinvoke\b", CurrentMatch.match[1], 1, false, "all") />

							<!--- If there are no matches then increment the amount of clean functions and skip the other checks  --->
							<cfif isArray(CfinvokeMatch) >

								<cfset structInsert(CurrentMatch, "InvokePositions", CfinvokeMatch) />
								<cfset arrayAppend(InvokesFound, CurrentMatch) />

							</cfif>

						</cfloop>

					<cfelse>
						<h3 class="good" >No CFOUTPUT-QUERY's found to check</h3>
						<cfset NoOutputs = true />
					</cfif>

					<cfif arrayLen(InvokesFound) GT 0 >

						<h3 class="bad" >Invokes inside CFOUTPUT-QUERY found:</h3>

						<cfloop array=#InvokesFound# index="CurrentCfoutput" >

							<cfset CfoutputLineNumber = mid( FileContents, 1, CurrentCfoutput.POS[1] ) />
							<cfset CfoutputLineNumber = listLen(CfoutputLineNumber, chr(13)) />

							<ul>
								<li>inside a cfoutput starting on line <b>#CfoutputLineNumber#:</b></li>
								<br/>

								<ul>

									<cfloop array=#CurrentCfoutput.InvokePositions# index="CurrentInvokePosition" >

										<cfset InvokeLineNumber = mid( FileContents, 1, (CurrentCfoutput.POS[1] + CurrentInvokePosition - 1) ) />
										<cfset InvokeLineNumber = listLen(InvokeLineNumber, chr(13)) />

										<li>on line: <u>#InvokeLineNumber#</u></li>

									</cfloop>

								</ul>
							</ul>
							
						</cfloop>

					<cfelse>
						<cfif NoOutputs IS false >
							<h3 class="good" >NO invokes found inside CFOUTPUT-QUERY</h3>
						</cfif>
					</cfif>
					
				</cfif>
		</cfoutput>
</body>
</html>