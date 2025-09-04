component implementsJava='java.net.http.WebSocket$Listener' {

    public any function onBinary(webSocket, data, last) output=false {}

    public any function onClose(webSocket, statusCode, reason) output=false {}

    public void function onError(webSocket, error) output=false {}

    public void function onOpen(webSocket) output = false {}

    public any function onPing(webSocket, message) output=false {}

    public any function onPong(webSocket, message) output=false {}

    public any function onText(webSocket, data, last) output=false {}
}