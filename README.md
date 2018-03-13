# Sandbox

This is simply a repo for me dumping things I am testing and messing with at any given time:

**FileUploadTest (Javascript)**: My first attempts at messing with FormData, FileList and File. I was curious about front end file validation (file sizes) and posting files using AJAX.

**2dCanvasRenderingTest (Javascript)**: Not my first attempt at drawing things with Canvas but definitely my most ambitious. I was searching for ideas for HTML UI-elements, and somehow ended up trying to create a basic radial menu myself. At the same time I got to brush up on trigonometry, even though I am not sure my math is done equally well, but this just ended up being for fun anyway.

**PromiseTest (Javascript)**: My latest work, checking out Promises, which ended up being an ideal solution for a message queing system that ties in with jQuery-animations. It also has elements of the module pattern (simulating object private-properties), freezing object properties (protecting them) and using consts.

**ThreadTest (Coldfusion)**: My very first attempt at working with multi-threading. This was a test to see if I could speed up processing a query with up to 10k records, where each row and column would be inspected and the data transformed, before being inserted into a struct. It never made it past prototype stage despite a noticable speed improvement, simply because our system isn't set up to properly handle multi-threading. And no one wanted the headache of debugging it if it broke.

**UnscopedVarChecker (Coldfusion)**: One of the challenges of working with a 10+ year old codebase that has had dozens of developers contribute to it is that the code qualtity and efficiency is all over the place. I made this tool to assist me in finding one of our key problems: globally scoped variable declarations inside of functions/methods (I can hear the compiled language-programmers shaking their heads right now). It was also the very first time I tackled regex, which I still consider to be black magic, despite understanding it a bit better after making this.

**NestedInvokeChecker (Coldfusion)**: Similar to above, this was an extension of that project. This tool was made to try and find temporal object invocations inside of loops. Although built after the above tool, it was still way more challenging, because I had to try and account for nested loops as well. Since most of the objects in our system are static, it's unnecessary - and quite performance unfriendly - to instantiate the same object every loop iteration and calling a method (or more methods) on it.
