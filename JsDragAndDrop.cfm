<cfif structIsEmpty(FORM) IS false >
	STATUS: DONE
	<cfabort/>
</cfif>

<!DOCTYPE html>
<html>

<head>
	<title>Form File Drag and Drop</title>
	<meta content="text/html; charset=utf-8" http-equiv="Content-Type" />
	<meta name="author" content="Thomas Frengler" />

	<script type="text/javascript" >

		const doCompatibilityCheck = function() {

			let passed = false;
			
			if (FormData) {
				passed = true;
				document.getElementById("formDataCheck").innerHTML = "YES";
				document.getElementById("formDataCheck").classList.add("good");
			};

			if (DragEvent) {
				passed = true;
				document.getElementById("dragEventCheck").innerHTML = "YES";
				document.getElementById("dragEventCheck").classList.add("good");
			};

			if (DataTransfer) {
				passed = true;
				document.getElementById("dataTransferCheck").innerHTML = "YES";
				document.getElementById("dataTransferCheck").classList.add("good");
			};

			if (XMLHttpRequestUpload) {
				passed = true;
				document.getElementById("xMLHttpRequestUploadCheck").innerHTML = "YES";
				document.getElementById("xMLHttpRequestUploadCheck").classList.add("good");
			};

			return passed;
		};

		<!--- A file structure in the global scope to keep track of our selected files --->
		const filesOnForm = Object.create(null);

		filesOnForm.file1 = null;
		filesOnForm.file2 = null;
		filesOnForm.file3 = null;
		// Prevent any keys from being added to our file structure
		Object.seal(filesOnForm);
		
		const onDragFileEnter = function(element, event) {
			event.preventDefault(); 
			
			element.classList.remove("containsFile");
			element.classList.add("fileOverHighlight");
		};

		const onDragFileExit = function(element, event) {
			event.preventDefault();

			element.classList.remove("fileOverHighlight");
			
			if (filesOnForm[element.id])
				element.classList.add("containsFile");					
		};

		const onDropFileOn = function(element, event) {

			event.preventDefault();
			element.classList.remove("fileOverHighlight");

			if (event.dataTransfer.items)
				filesOnForm[element.id] = event.dataTransfer.items[0].getAsFile();
			// Not sure what to put in the else-block but some browsers may use a "file"-key instead of "items"
			
			element.classList.add("containsFile");
			updateFileField(element.id);
		};

		const updateFileField = function(id) {

			const fileDetailsField = document.querySelector("#" + id + "Details");
			const fileInteractionField = document.querySelector("#" + id + "Interaction");

			if (filesOnForm[id]) {

				fileInteractionField.innerText = "CLICK TO REMOVE";
				fileInteractionField.addEventListener("click", ()=> {
					onRemoveFile(id);
				});

				fileDetailsField.innerHTML = `<b>NAME</b>: ${filesOnForm[id].name} | `;
				fileDetailsField.innerHTML += `<b>TYPE</b>: ${filesOnForm[id].type} | `;
				fileDetailsField.innerHTML += `<b>SIZE</b>: ${filesOnForm[id].size} bytes`;

				return;
			}

			fileInteractionField.innerText = "DRAG AND DROP";
			fileDetailsField.innerText = "";
		};

		const onRemoveFile = function(id) {

			filesOnForm[id] = null;
			document.querySelector("#" + id).classList.remove("containsFile");	
			updateFileField(id);
		};

		const uploadForm = function() {

			const httpRequest = new XMLHttpRequest();
			httpRequest.open("POST", "/Tools/Thomas/FileDragAndDrop/index.cfm", true);
			// Create a fancy form object from the FormData API. We pass our form-element into the constructor so it has all our fields
			const POSTData = new FormData(document.getElementById("TestForm"));
			
			// Time to add all the files we uploaded. If we used file-input fields this wouldn't be needed of course
			// I wanted to show off the alternative of doing it ourselves, without being shackled to input-fields, as many HTML
			// pages these days use these fancy drop zones rather then input fields
			for (let key in filesOnForm) {
				if (filesOnForm[key])
					POSTData.append(key, filesOnForm[key], filesOnForm[key].name);
			};

			// Setting up event handlers for the upload-object the request, so we can track its state

			// Fired the moment the request is sent off to the remote server
			httpRequest.upload.addEventListener('loadstart', ()=> {
				document.getElementById("submitButton").disabled = true;
				document.getElementById("uploadProgress").value = 0;
				document.getElementById("uploadStatus").innerText = "IN PROGRESS";
			});

			// Fired when the upload finished, regardless of whether its a success or failure
			httpRequest.upload.addEventListener('load', ()=> {
				document.getElementById("uploadStatus").innerText = "DONE!";
				document.getElementById("submitButton").disabled = false;
			});

			// These two speak for themselves. Abort is usually a user action
			httpRequest.upload.addEventListener('error', ()=> document.getElementById("uploadStatus").innerText = "ERROR");
			httpRequest.upload.addEventListener('abort', ()=> document.getElementById("uploadStatus").innerText = "ABORTED");

			// Fired whenever the http request pulses/updates. This is how we track the upload progress and give the user feedback
			httpRequest.upload.addEventListener('progress', (event)=> {

				// Length needs to be computable before we can do anything
				if (event.lengthComputable) {

					document.getElementById("totalBytes").innerHTML = getReadableBytes(event.total);
					document.getElementById("uploadProgress").max = event.total;
					document.getElementById("uploadProgress").value = event.loaded;
					document.getElementById("progressPercentage").innerText = ` ${Math.floor((event.loaded / event.total) * 100)}%`;
					document.getElementById("uploadedBytes").innerText = getReadableBytes(event.loaded);

				};

			});

			// Fire away! Let magic happen
			httpRequest.send(POSTData);
		};

		// Some funky, manual calculations of how big the form is but it turned out not to be needed. Just here for vanity's sake really
		const calculateFormSize = function(FormObject) {

			const FormEntries = FormObject.entries();
			let nextEntry = FormEntries.next();
			let totalSize = 0;

			while (!nextEntry.done) {
				let formEntryValue = nextEntry.value[1];

				if (formEntryValue.length) 
					totalSize += formEntryValue.length;
				else if (formEntryValue.size) 
					totalSize += formEntryValue.size;

				nextEntry = FormEntries.next();
			};

			return totalSize;
		};

		const getReadableBytes = function(bytes) {
			var i = Math.floor(Math.log(bytes) / Math.log(1024));
			const sizes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];

			return (bytes / Math.pow(1024, i)).toFixed(2) * 1 + ' ' + sizes[i];
		};
	</script>

	<style type="text/css">
		
		.fileZone {
			display: inline-block;
			padding: 1em;
			margin-bottom: 1em;
		}

		.fileOverHighlight {
			box-shadow: 0 3px 6px rgba(0,0,0,0.3), inset 0 -3px 3px rgba(0,0,0,0.1);
			border: solid #ccc 1px;
		}

		.containsFile {
			box-shadow: 0 3px 6px rgba(0,255,0,0.3), inset 0 -3px 3px rgba(0,255,0,0.1);
			border: solid #ccc 1px;
		}

		#demo {
			display: none;
		}

		.good {
			background-color: green;
			color: white;
		}

		.bad {
			background-color: red;
			color: white;
		}

	</style>

	<script type="text/javascript">
		window.onload = function() {
			// Init stuff once the page is ready. Mostly event handlers in our case

			if (!doCompatibilityCheck())
				return;

			document.getElementById("compatibilityCheck").style.display = "none";

			document.querySelectorAll(".fileZone").forEach((value)=> {
				
				value.addEventListener("dragenter", (event)=> {
					onDragFileEnter(value, event)
				});

				value.addEventListener("dragexit", (event)=> {
					onDragFileExit(value, event)
				});

				value.addEventListener("drop", (event)=> {
					onDropFileOn(value, event)
				})
			});

			document.getElementById("submitButton").addEventListener("click", uploadForm);

			// These are needed to prevent the files from opening in the browser window when you drop them anywhere on the page
			window.addEventListener("dragover", (event)=> {
				event.preventDefault();
			});
			window.addEventListener("dragenter", (event)=> {
				event.preventDefault();
			});
			window.addEventListener("drop", (event)=> {
				event.preventDefault();
			});

			console.log("Ready to rock and roll");
			document.getElementById("demo").style.display = "block";
		};
	</script>
</head>

<body>

	<section id="compatibilityCheck" >

		<h1>COMPATIBILITY CHECK:</h1>
		
		<ul>
			<li>FormData: <b><span class="bad" id="formDataCheck">NO</span></b></li>
			<li>DragEvent: <b><span class="bad" id="dragEventCheck">NO</span></b></li>
			<li>DataTransfer: <b><span class="bad" id="dataTransferCheck">NO</span></b></li>
			<li>XMLHttpRequestUpload: <b><span class="bad" id="xMLHttpRequestUploadCheck">NO</span></b></li>
		</ul>

		<p>Your browser isn't good enough, sorry</p>
	</section>

	<section id="demo">
		<form enctype="multipart/form-data" id="TestForm" name="TestForm" action="" method="POST" >

			<p>
				<span>First name: </span>
				<input type="text" name="firstName" placeholder="first name" />
			</p>

			<p>
				<span>Last name: </span>
				<input type="text" name="lastName" placeholder="last name" />
			</p>

			<p>
				<span>Date of birth: </span>
				<input type="date" name="dateOfBirth" placeholder="date of birth" />
			</p>

			<p>
				<span>How awesome are you?: </span>
				<input type="number" name="awesomeRating" placeholder="between 0 and 9000" min="0" max="9000" />
			</p>

			<section id="file1" class="fileZone" >
				<span>File 1: </span>
				<span id="file1Interaction">DRAG AND DROP</span><br/>
				<span>File details: </span><span id="file1Details"></span>
			</section><br/>

			<section id="file2" class="fileZone" >
				<span>File 2: </span>
				<span id="file2Interaction">DRAG AND DROP</span><br/>
				<span>File details: </span><span id="file2Details"></span>
			</section><br/>

			<section id="file3" class="fileZone" >
				<span>File 3: </span>
				<span id="file3Interaction">DRAG AND DROP</span><br/>
				<span>File details: </span><span id="file3Details"></span>
			</section><br/>

		</form>

		<p>
			<input id="submitButton" type="button" value="SUBMIT FORM" />
		</p>

		<section id="formProgress" >
			<ul>
				<li>TOTAL FORM SIZE: <b><span id="totalBytes"></span></b></li>
				<li>UPLOADED: <b><span id="uploadedBytes"></span></b></li>
				<li>PROGRESS: <progress id="uploadProgress" value="0" max="100" ></progress><b><span id="progressPercentage"> 0%</span></b></li>
				<li>STATUS: <b><span id="uploadStatus" >NOT STARTED</span></b></li>
			</ul>
		</section>

	</section>

</body>