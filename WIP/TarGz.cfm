<cfscript>
rootDir = getDirectoryFromPath(getCurrentTemplatePath());

public void function ExtractTarGz(required any tarAsByteArray, required string outputFileName)
{
    var InputStream = createObject("java", "java.io.ByteArrayInputStream").init(arguments.tarAsByteArray);
    var GZIPInputStream = createObject("java", "java.util.zip.GZIPInputStream").init(InputStream);
    var OutputStream = createObject("java", "java.io.FileOutputStream").init("#rootDir#/#outputFileName#");

    var EmptyByteArray = createObject("java", "java.io.ByteArrayOutputStream").init().toByteArray();
    var Buffer = createObject("java","java.lang.reflect.Array").newInstance(EmptyByteArray.getClass().getComponentType(), 1024);
    var Length = GZIPInputStream.read(Buffer);

    while(Length != -1)
    {
        OutputStream.write(Buffer, 0, Length);
        Length = GZIPInputStream.read(Buffer);
    }

    OutputStream.close();
    GZIPInputStream.close();
}

// https://msedgewebdriverstorage.blob.core.windows.net/edgewebdriver/90.0.818.56/edgedriver_win64.zip
// HTTPService = new http(url="https://github.com/mozilla/geckodriver/releases/download/v0.29.1/geckodriver-v0.29.1-linux64.tar.gz", method="GET", timeout="10", redirect="true");
// DownloadReponse = HTTPService.send().getPrefix();

// writeDump(DownloadReponse);
// ExtractTarGz(DownloadReponse.fileContent, "geckodriver.exe");
cfexecute(name="bash", "tar -xf #rootDir#/#outputFileName# -C #rootDir#", timeout="5", variable="UntarResult");

</cfscript>

<!--- try {
    FileInputStream fis = new FileInputStream(gzipFile);
    GZIPInputStream gis = new GZIPInputStream(fis);
    FileOutputStream fos = new FileOutputStream(newFile);
    byte[] buffer = new byte[1024];
    int len;
    while((len = gis.read(buffer)) != -1){
        fos.write(buffer, 0, len);
    }
    //close resources
    fos.close();
    gis.close();
} catch (IOException e) {
    e.printStackTrace();
} --->