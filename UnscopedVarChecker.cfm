<cfprocessingdirective pageencoding="utf-8" />
<!DOCTYPE html>

<html>

	<head>
		<title>Find unscoped vars</title>
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

			table {
				border-style: solid;
				border-width: 1px;
				border-color: #3d5c5c;
			}

			td {
				text-align: center;
				padding-left: 0.5em;
				padding-right: 0.5em;
			}

			th {
				padding-left: 0.5em;
				padding-right: 0.5em;
				text-align: center;
				background-color: #3d5c5c;
				color: white;
			}

			tr:nth-child(odd) {
				background-color: #e6e6e6;
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

			.function_title {
				background-color: #3d5c5c;
				color: white;
			}
		</style>
	</head>

	<body>
	<cfoutput>

		<cfset ProcessFile = false />
		<h1>FIND UNSCOPED VARIABLES IN FUNCTIONS</h1>
		<hr/>

		<form name="ScanFileFORM" action="UnscopedVarChecker.cfm" enctype="application/x-www-form-urlencoded" method="post" >
			<div id="FormElementsContainer">

				<p>
					<div>FILE TO SCAN:</div>
					<input type="text" name="FileToScan" value=<cfif isDefined("FORM.FileToScan") AND len(FORM.FileToScan) GT 0 >"#FORM.FileToScan#"<cfelse>""</cfif> placeholder="absolute path" />
					<br/><br/>
					<input id="SubmitButton" type="submit" value="SCAN FILE" />
				</p>

				<span>
					Use this tool to scan cfc- or cfm-files for unscoped variables. There are some limitations:
					<ul>
						<li>It can't handle nested functions. It finds functions by searching for &lt;cffunction, any characters and whitespace, and then the end cffunction-tag</li>
						<li>It can't account for implicit scope cascading, like doing assigment to a private or global variable without specificing a scope such as variables.xxx</li>
						<li>The line numbers are found by converting the file contents to a list, using CR as a delimiter. So that may not work correctly on Mac or Unix systems</li>
						<li>It only checks for cfset's that aren't var-scoped. Things like cfloop index-vars, cffile results-vars, query name-vars etc are not covered</li>
						<li>Due to CF regex not supporting lookbehind it can't reliably check for commented out code</li>
						<li>Crazy/dumb/non-standard variations in syntax. Although double spaces between the variable name and the equal sign are accounted for, if there are things like tabs or newline it wouldn't recognize it</li>
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

			<cfset FileContents = "" />
			<cfset FileToParse = FORM.FileToScan />
			<cfset CfSetScopedCapture = "<cfset\b\s*var\s*\w+\s*=" />
			<cfset CfsetVarNameCapture = "\w+(?=\s+=)" />
			<cfset CfSetCapture = "<cfset\b(?!(\s*\w+\()|\s*\w+\.\w+\()\s*\w+\s*=" />
			<cfset FunctionCapture = "<cffunction[\S\s]+?</cffunction>" />
			<!--- <cfset FunctionNameCapture = "(?<=name=[""|'])(\w+)(?=[""|'])" />  No lookbehind in CF sadly --->
			<cfset FunctionNameCapture = "name=""(.+?)""" />
			<cfset LoopCounter = 0 />
			<cfset FunctionNameMatch = arrayNew(1) />
			<cfset FunctionMatches = arrayNew(1) />
			<cfset ProcessedVars = arrayNew(1) />
			<cfset CleanFunctions = 0 />
			<cfset UnscopedVarsVerified = 0 />
			<cfset UnscopedVarOutput = "" />
			<cfset UnscopedTableContent = "" />
			<cfset UnscopedVarName = arrayNew(1) />

			<cffile action="read" file=#FileToParse# variable="FileContents" />

			<!--- NO nested functions supported! --->
			<cfset FunctionMatches = reFindNoCase(FunctionCapture, FileContents, 1, true, "all") />

			<cfif arrayLen(FunctionMatches) IS 1 AND FunctionMatches[1].POS[1] IS 0 >
				<h3 class="bad" >No functions found in file</h3>
				</body>
				</html>
				<cfabort>
			</cfif>

			<cfloop array=#FunctionMatches# index="CurrentMatch" >

				<!--- 
					Attempt at compensating for rare instances of strings or regex's that may contain text that happens to match our regex pattern. 
					50 seems a reasonable minimum for even a bare bones function definition.
				--->
				<cfif len(CurrentMatch.match[1]) LT 50 >
					<cfcontinue/>
				</cfif>

				<cfset LoopCounter++ />
				<cfset FunctionNameMatch = reFindNoCase(FunctionNameCapture, CurrentMatch.match[1], 1, true) />

				<cfif FunctionNameMatch.LEN[1] GT 0 AND arrayLen(FunctionNameMatch.match) IS 2 >
					<cfset structInsert(FunctionMatches[LoopCounter], "FunctionName", FunctionNameMatch.match[2]) />
				<cfelse>
					<cfthrow message="Unable to get extract function name" detail="Concerns function starting at position #FunctionMatches[LoopCounter].POS[1]#" />
				</cfif>

			</cfloop>

			<!--- Loop through all functions and check for unscoped cfset's --->
			<cfset LoopCounter = 0 />
			<cfloop array=#FunctionMatches# index="CurrentMatch" >

				<!--- Resetting these on each iteration otherwise we end up with data from previous runs --->
				<cfset ProcessedVars = arrayNew(1) />
				<cfset UnscopedTableContent = "" />

				<cfset LoopCounter++ />
				<cfset UnscopedVarMatch = reFindNoCase(CfSetCapture, CurrentMatch.match[1], 1, true, "all") />

				<!---
					Finding the line number is a matter of extracting all contents from the start of the file to the beginning of the cffunction-tag.
					After that we treat our text as a list, with carriage returns serving as delimiters, which breaks the text down to lines. Since
					we know that the function is on the last line, we simply need to know the length.
				--->
				<cfset FunctionLineNumber = mid( FileContents, 1, FunctionMatches[LoopCounter].POS[1] ) />
				<cfset FunctionLineNumber = listLen(FunctionLineNumber, chr(13)) />

				<!--- If there are no matches then increment the amount of clean functions and skip the other checks  --->
				<cfif arrayLen(UnscopedVarMatch) IS 1 AND UnscopedVarMatch[1].LEN[1] IS 0 >
					<cfset CleanFunctions++ />
				<cfelse>
					<!--- Loop through the unscoped matches and check them --->
					<cfloop array=#UnscopedVarMatch# index="CurrentUnscopedVar" >
						<cfset UnscopedVarOutput = "" />

						<!--- We are only interested in the first occurence. The others are likely assignments and cause double redundant checks --->
						<cfif arrayFind(ProcessedVars, CurrentUnscopedVar.match[1]) IS 0 >

							<!--- 
								We have to check an extra time if the variable has really been declared because it could be this occurence is an
								innocent assignment, which would still trigger our regex pattern. If we get a match, then skip this iteration.
							--->
							<cfset UnscopedVarName= reFindNoCase(CfsetVarNameCapture, CurrentUnscopedVar.match[1], 1, true) />
							<cfif findNoCase("<cfset var #UnscopedVarName.match[1]#", FunctionMatches[LoopCounter].match[1]) GT 0 >
								<cfset UnscopedVarsVerified++ />
								<cfcontinue/>
							</cfif>

							<!--- If we get to here it means we have ourselves an unscoped variable, we then add to our screen output for later --->
							<cfsavecontent variable="UnscopedVarOutput" >
								<tr>
									<!--- 
										Finding the line number here requires that we add our match unscoped var position to the start position of the function.
										We can't simply rely on extracting from the filecontents based on the unscaped var position, because it's position value
										from the match is relative to the contents of the function-tag contents, and not the entire file we are scanning.
									--->
									<cfset CfsetLineNumber = mid( FileContents, 1, (FunctionMatches[LoopCounter].POS[1] + CurrentUnscopedVar.POS[1] - 1) ) />
									<cfset CfsetLineNumber = listLen(CfsetLineNumber, chr(13)) />

									<td>#htmlEditFormat(CurrentUnscopedVar.match[1])#</td>
									<td>#CfsetLineNumber#</td>
									<cfset arrayAppend(ProcessedVars, CurrentUnscopedVar.match[1]) />
								</tr>
							</cfsavecontent>

							<cfset UnscopedTableContent = (UnscopedTableContent & UnscopedVarOutput) />
						</cfif>
					</cfloop>

					<!--- If there are any unscoped vars then output the result to screen --->
					<cfif UnscopedVarsVerified LT arrayLen(UnscopedVarMatch) >

						<h2 class="bad function_title" >#CurrentMatch.FunctionName#(): line #FunctionLineNumber#</h2>

						<table>
							<thead>
								<th>VARIABLE</th>
								<th>LINE</th>
							</thead>

							<tbody>
								#UnscopedTableContent#
							</tbody>

						</table>
					<cfelse>
						<cfset CleanFunctions++ />
					</cfif>

				</cfif>

			</cfloop>

			<cfif arrayLen(FunctionMatches) EQ CleanFunctions >
				<h2 class="good" >No unscoped variables found in any functions!</h2>
			</cfif>

		</cfif>

	</cfoutput>
	</body>
</html>