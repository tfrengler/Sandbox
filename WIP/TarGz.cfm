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
// HTTPService = new http(url="https://msedgewebdriverstorage.blob.core.windows.net/edgewebdriver/LATEST_STABLE", method="GET", timeout="10", redirect="true");
// DownloadReponse = HTTPService.send().getPrefix();

// writeDump(DownloadReponse);
// ExtractTarGz(DownloadReponse.fileContent, "geckodriver.exe");
// cfexecute(name="bash", "tar -xf #rootDir#/#outputFileName# -C #rootDir#", timeout="5", variable="UntarResult");

</cfscript>

<cffunction name="ExtractTar" access="public" returntype="void" output="true" >
    <cfargument name="tarFileName" type="string" required="true" />
    <cfscript>
        try
        {
            var File = createObject("java", "java.io.File").init(getTempDirectory() & arguments.tarFileName);
            var InputStream = createObject("java", "java.io.FileInputStream").init(File);
            var EmptyByteArray = createObject("java", "java.io.ByteArrayOutputStream").init().toByteArray();
            var InputBuffer = createObject("java","java.lang.reflect.Array").newInstance(EmptyByteArray.getClass().getComponentType(), 100);

            InputStream.read(InputBuffer, 0, 100);
            var Name = createObject("java", "java.lang.String").init(InputBuffer, "US-ASCII");
            Name = REreplace(Name, "[\x0]", "", "ALL");

            InputStream.skip(24);
            InputStream.read(InputBuffer, 0, 12);

            var ByteSubset = createObject("java", "java.util.Arrays").copyOfRange(InputBuffer, 0, 12);
            var SizeAsString = createObject("java", "java.lang.String").init(ByteSubset, "UTF-8");
            SizeAsString = REreplace(SizeAsString, "[\x0]", "", "ALL");
            var FinalSize = createObject("java", "java.lang.Long").parseUnsignedLong(val(SizeAsString), 8);

            InputStream.skip(376);

            var OutputPathAndFileName = "#rootDir##Name#";
            var OutputStream = createObject("java", "java.io.FileOutputStream").init(OutputPathAndFileName);
            var OutputBuffer = createObject("java","java.lang.reflect.Array").newInstance(EmptyByteArray.getClass().getComponentType(), FinalSize);

            InputStream.read(OutputBuffer, 0, FinalSize);
            OutputStream.write(OutputBuffer);
        }
        catch(any error)
        {
            rethrow;
        }
        finally
        {
            InputStream.close();
            OutputStream.close();
        }
    </cfscript>
</cffunction>

<cfset ExtractTar() />

<!---
    public static void ExtractTar(Stream stream, string outputDir)
    {
        var buffer = new byte[100];
        while (true)
        {
            stream.Read(buffer, 0, 100);
            var name = Encoding.ASCII.GetString(buffer).Trim('\0');
            if (String.IsNullOrWhiteSpace(name))
                break;
            stream.Seek(24, SeekOrigin.Current);
            stream.Read(buffer, 0, 12);
            var size = Convert.ToInt64(Encoding.UTF8.GetString(buffer, 0, 12).Trim('\0').Trim(), 8);

            stream.Seek(376L, SeekOrigin.Current);

            var output = Path.Combine(outputDir, name);
            if (!Directory.Exists(Path.GetDirectoryName(output)))
                Directory.CreateDirectory(Path.GetDirectoryName(output));
            if (!name.Equals("./", StringComparison.InvariantCulture))
            {
                using (var str = File.Open(output, FileMode.OpenOrCreate, FileAccess.Write))
                {
                    var buf = new byte[size];
                    stream.Read(buf, 0, buf.Length);
                    str.Write(buf, 0, buf.Length);
                }
            }

            var pos = stream.Position;

            var offset = 512 - (pos  % 512);
            if (offset == 512)
                offset = 0;

            stream.Seek(offset, SeekOrigin.Current);
        }
    }
--->