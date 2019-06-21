<cfset sRootDir = getDirectoryFromPath( getCurrentTemplatePath() ) />
<!--- We'll pull values from CF here, but these are defaults --->

<!--- Choices are: SMTP, SMTPS, SMTP_TLS --->
<cfset nSecurityModel = application.oJavaloader.create("org.simplejavamail.mailer.config.TransportStrategy").SMTP_TLS />
<cfset sRemoteSMTPHost = "smtp.gmail.com" />
<cfset nPortSMTP = 587 />
<cfset sUsernameSMTP = "thomasfrengler@gmail.com" />
<cfset sPasswordSMTP = "XXXXXX" />
<cfset sDefaultSubject = "Subject" />
<cfset sDefaultTo = "thomasgrudfrengler@hotmail.com" />
<cfset sDefaultFrom = "tfrengler@talentsoft.com" />
<cfset nDefaultPoolSize = 10 /> <!--- Thread pool size, for async mail sending --->
<cfset bDebugLoggingJavaMailer = "true" />
<cfset nSessionTimeout = 30000 />
<cfset bLogModeOnly = true />

<cfoutput>

<p>OUR HARDCODED CONFIG:</p>
<ul>
	<li><u>nSecurityModel</u>: #nSecurityModel#</li>
	<li><u>sRemoteSMTPHost</u>: #sRemoteSMTPHost#</li>
	<li><u>nPortSMTP</u>: #nPortSMTP#</li>
	<li><u>sUsernameSMTP</u>: #sUsernameSMTP#</li>
	<li><u>sPasswordSMTP</u>: #sPasswordSMTP#</li>
	<li><u>sDefaultSubject</u>: #sDefaultSubject#</li>
	<li><u>sDefaultTo</u>: #sDefaultTo#</li>
	<li><u>sDefaultFrom</u>: #sDefaultFrom#</li>
	<li><u>nDefaultPoolSize</u>: #nDefaultPoolSize#</li>
	<li><u>bDebugLoggingJavaMailer</u>: #bDebugLoggingJavaMailer#</li>
	<li><u>nSessionTimeout</u>: #nSessionTimeout#</li>
	<li><u>Log-mode only:</u> #bLogModeOnly#</li>
</ul>

<cftimer label="Attachments creation and checking" type="inline" >

<!--- Create an inline file ie. not from an external source --->
<cfset oInlineAttachment = application.oJavaloader.create("javax.mail.util.ByteArrayDataSource").init("This is a test", "text/plain") />
<p>Inline attachment created ("This is a test", "text/plain")</p>

<!--- The rest of our attachments, this time using actual files from disk --->
<cfset oFile1 = createObject("java", "java.io.File").init("C:\Dev\codebase\lucee\DevTests\Selenium\Docs\metadata.txt") />
<cfif oFile1.canRead() >
	<p>File 1 exists, and can be read</p>
<cfelse>
	<p><b>File 1 cannot be read!</b> <u>#oFile1#</u></p>
</cfif>
<cfset oDataSource1 = application.oJavaloader.create("javax.activation.FileDataSource").init(oFile1) />

<cfset oFile2 = createObject("java", "java.io.File").init("C:\Dev\codebase\lucee\DevTests\Selenium\Docs\Test1docx.docx") />
<cfif oFile1.canRead() >
	File 2 exists, and can be read</p>
<cfelse>
	<p><b>File 2 cannot be read!</b> <u>#oFile2#</u></p>
</cfif>
<cfset oDataSource2 = application.oJavaloader.create("javax.activation.FileDataSource").init(oFile2) />

</cftimer><br/>

<!--- This thing can (and probably should) be re-used --->
<cfset oEmailFactory = application.oJavaloader.create("org.simplejavamail.email.EmailBuilder") />

<!--- Non-configurable class that represents the final email to be sent --->
<cftimer label="oOutboundEmail creation" type="inline" >
<cfset oOutboundEmail = oEmailFactory.startingBlank()
	.to(sDefaultTo)
	.from(sDefaultFrom)
	.withSubject("TLS1.2 testing")
	.appendTextHTML("How are you doing?")
	.withAttachment("Test.txt", oDataSource1)
	.withAttachment(nullValue(), oDataSource2)
	.withAttachment("ByteArraySourceTest.txt", oInlineAttachment)
	.buildEmail()
/>
</cftimer><br/>

<p>EMAIL DATA:</p>
<ul>
	<li><u>ATTACHMENTS</u>: #arrayLen(oOutboundEmail.getAttachments())#</li>
	<li><u>SUBJECT</u>: #oOutboundEmail.getSubject()#</li>
	<li><u>HTML BODY</u>: #oOutboundEmail.getHTMLText()#</li>
</ul>

<!--- The mailer, responsible for sending the emails. Can and should definitely be re-used for performance reasons! --->

<cftimer label="oMailer creation" type="inline" >
<cfset oMailer = application.oJavaloader.create("org.simplejavamail.mailer.MailerBuilder")
	<!--- Set all parameter through chaining so we don't need to use a config file --->
	.withTransportStrategy(nSecurityModel)
	.withSMTPServerHost(sRemoteSMTPHost)
	.withSMTPServerPort(nPortSMTP)
	.withSMTPServerUsername(sUsernameSMTP)
	.withSMTPServerPassword(sPasswordSMTP)
	.withDebugLogging(bDebugLoggingJavaMailer)
	.withSessionTimeout(nSessionTimeout)
	.withTransportModeLoggingOnly(bLogModeOnly)
	.buildMailer()
/>
</cftimer><br/>

<p>MAILER CONFIG:</p>
<ul>
	<li><u>Session timeout:</u> #oMailer.getOperationalConfig().getSessionTimeout()# ms</li>
	<li><u>Thread pool size:</u> #oMailer.getOperationalConfig().getThreadPoolSize()#</li>
	<li><u>Debug logging:</u> #oMailer.getOperationalConfig().isDebugLogging()#</li>
	<li><u>Log-mode only:</u> #oMailer.getOperationalConfig().isTransportModeLoggingOnly()#</li>
	<li><u>Host:</u> #oMailer.getServerConfig().getHost()#</li>
	<li><u>Password:</u> #oMailer.getServerConfig().getPassword()#</li>
	<li><u>Port:</u> #oMailer.getServerConfig().getPort()#</li>
	<li><u>Username:</u> #oMailer.getServerConfig().getUsername()#</li>
	<li><u>Transport strategy:</u> #oMailer.getTransportStrategy()#</li>
</ul>

<p>OBJECT SIZES:</p>
<ul>
	<li>oMailer: #numberFormat(sizeOf(oMailer) / 1000, "9.99")# kb</li>
	<li>oOutboundEmail: #numberFormat(sizeOf(oOutboundEmail) / 1000, "9.99")# kb</li>
	<li>oEmailFactory: #numberFormat(sizeOf(oEmailFactory) / 1000, "9.99")# kb</li>
	<li>oJavaloader: #numberFormat(sizeOf(application.oJavaloader) / 1000, "9.99")# kb</li>
</ul>

<cftry>
	<cfset oMailer.testConnection() />
	<p>Connection to remote mail server successfull!</p>
	
	<cfcatch>
		<p><b>Can't connect to the remote mail server :(</b></p>
		<cfrethrow>
	</cfcatch>
</cftry>

<cfset oMailer.sendMail(oOutboundEmail) />
<p>Mail sent</p>
<cfif oMailer.getOperationalConfig().isTransportModeLoggingOnly() >
	<p><b>...but not for real, because TransportModeLoggingOnly is ON</b></p>
</cfif>

</cfoutput>