# Sandbox

This is simply a repo for me dumping things I am testing and messing with at any given time:

**FileUploadTest (Javascript)**: My first attempts at messing with FormData, FileList and File. I was curious about front end file validation (file sizes) and posting files using AJAX.

**2dCanvasRenderingTest (Javascript)**: Not my first attempt at drawing things with Canvas but definitely my most ambitious. I was searching for ideas for HTML UI-elements, and somehow ended up trying to create a basic radial menu myself. At the same time I got to brush up on trigonometry, even though I am not sure my math is done equally well, but this just ended up being for fun anyway.

**PromiseTest (Javascript)**: My latest work, checking out Promises, which ended up being an ideal solution for a message queing system that ties in with jQuery-animations. It also has elements of the module pattern (simulating object private-properties), freezing object properties (protecting them) and using consts.

**ThreadTest (Coldfusion)**: My very first attempt at working with multi-threading. This was a test to see if I could speed up processing a query with up to 10k records, where each row and column would be inspected and the data transformed, before being inserted into a struct. It never made it past prototype stage despite a noticable speed improvement, simply because our system isn't set up to properly handle multi-threading. And no one wanted the headache of debugging it if it broke.

**UnscopedVarChecker (Coldfusion)**: One of the challenges of working with a 10+ year old codebase that has had dozens of developers contribute to it is that the code qualtity and efficiency is all over the place. I made this tool to assist me in finding one of our key problems: globally scoped variable declarations inside of functions/methods (I can hear the compiled language-programmers shaking their heads right now). It was also the very first time I tackled regex, which I still consider to be black magic, despite understanding it a bit better after making this.

**NestedInvokeChecker (Coldfusion)**: Similar to above, this was an extension of that project. This tool was made to try and find temporal object invocations inside of loops. Although built after the above tool, it was still way more challenging, because I had to try and account for nested loops as well. Since most of the objects in our system are static, it's unnecessary - and quite performance unfriendly - to instantiate the same object every loop iteration and calling a method (or more methods) on it.

**JSDragAndDrop (Javascript)**: Me playing around with the Drag & Drop API in Javascript. I had to create a prototype for work, as we were considering implementing it, and I decided to add it to my own repo in case I ever want to use it for something myself.

**StateMachineTest (Javascript)**: Prototyping a state machine, in combination with the FileReader API. Not for any particular reason other than I've read about state machines and wanted to check it out myself.

**SimpleJavaMail (Coldfusion/Java)**: A prototype built for my work as we had trouble getting Lucee to support TLS 1.2. Using a library to send the emails instead of the internal cfmail-tag was the only workaround, hence why we went with this solution. The most difficult part was getting SimpleJavaMail to pick up and use its own bundled versions of javax.mail and javax.activation, as they would constantly be overruled by Lucee's internal versions. As usual, Mark Mandel's awesome Javaloader saved the day.

**StreamTest (Javascript)**: A test where I manually stream an audio file using fetch() and range-byte headers. It's based on a lot of methods that are still in draft and thus subject to bugs, different browsers implementations and possible changes. It uses an HTMLMediaElement, coupled with a MediaSource where data fetched in chunks (as arrayBuffers) are added/appended to the MediaSource's sourceBuffer. It works pretty damn well but there are a few caveats:
* It only works on Chrome. FF has multiple bugs and doesn't support decoding MP3 in sourceBuffers apparently
* Audio filesize: sourceBuffer's for audio can only hold about 12-15 MB (depending on browser). So if you want to stream a bigger file than that you'll have to stagger the internal buffering of the sourceBuffer depending on where the current play-time is, and/or remove data from the sourceBuffer that the play-time has passed. Either way, it's complicated - even more so if you want to support seeking.
* If you want to copy this example wholesale you obviously need to replace FETCH_ENTRY_POINT with a file/URL that returns an audio file for it to work

**TableDragAndDrop (Javascript)**: Another drag and drop prototype, but where the previous one had to do with uploading files, this was for re-arranging HTML-elements, specifically rows in a table

**Physics-folder (Javascript)** My own implementation of Nature of Code (https://natureofcode.com/book/), with the aim of making some small, prototype physics-based game

**CF_SQLite** Super-simple example on how to get SQLite loaded into Lucee with a minimum of fuss. Just requires the SQLite JDBC driver (https://bitbucket.org/xerial/sqlite-jdbc/downloads/)