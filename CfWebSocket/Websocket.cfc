component implementsJava="java.net.http.WebSocket$Listener" {
    public java.util.concurrent.CompletionStage function onBinary (java.net.http.WebSocket webSocket, java.nio.ByteBuffer data, boolean last) type='java' { return null; }
    public java.util.concurrent.CompletionStage function onClose (java.net.http.WebSocket webSocket, int statusCode, String reason) type='java' { return null; }
    public void function onError (java.net.http.WebSocket webSocket, java.lang.Throwable error) type='java' {}
    public void function onOpen (java.net.http.WebSocket webSocket) type='java' {}
    public java.util.concurrent.CompletionStage function onPing (java.net.http.WebSocket webSocket, java.nio.ByteBuffer message) type='java' { return null; }
    public java.util.concurrent.CompletionStage function onPong (java.net.http.WebSocket webSocket, java.nio.ByteBuffer message) type='java' { return null; }
    public java.util.concurrent.CompletionStage function onText (java.net.http.WebSocket webSocket, java.lang.CharSequence data, boolean last) type='java' { return null; }
}