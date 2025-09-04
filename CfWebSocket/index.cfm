<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8" />
    <title>CfWebsocket</title>

    </head>
    <body>

        <cfscript>
            // test = new WebSocket();
            // writeDump(test);

            // HttpClient = createObject('java', 'java.net.http.HttpClient');
            // Version = createObject('java', 'java.net.http.HttpClient$Version');
            // Redirect = createObject('java', 'java.net.http.HttpClient$Redirect');
            // Duration = createObject('java', 'java.time.Duration');

            // HttpClient.newBuilder()
            //     .version(Version.HTTP_1_1)
            //     .followRedirects(Redirect.NORMAL)
            //     .connectTimeout(Duration.ofSeconds(20))
            //     .build();

            // writeDump(HttpClient);

            // HttpClient = createObject('java', 'java.net.http.HttpClient');
            // URI = createObject('java', 'java.net.URI');

            // writeDump(createObject('java', 'java.net.http.WebSocket$Listener'));
            // abort;

            websocket = new WebSocket();
            // listenerClass = createObject("java", "java.net.http.WebSocket$Listener");
            // writeDump(listenerClass.getClass().getName());abort;
            // ws = CreateDynamicProxy(websocket, ['java.net.http.WebSocket$Listener']);
            // ws = javaCast('java.net.http.WebSocket$Listener', websocket);
            // ws = javaCast('java.lang.CharSequence', websocket);
            // writeDump(ws);

            // test = HttpClient.newHttpClient()
            //     .newWebSocketBuilder()
            //     .buildAsync(
            //         URI.create("wss://yourserver.com"),
            //         websocket
            //     )
            //     .join();

            // writeDump(test);

            classLoader = getPageContext().getConfig().getClassLoaderEnv();
            writeDump(classLoader.loadClass('java.net.http.WebSocket$Listener'));
        </cfscript>

    </body>
</html>