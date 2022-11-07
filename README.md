Simple Http-Server Test using `System.Net.HttpListener`

### Start Server
Spawn the Http Server in your root directory or pass the directory to the `Root` parameter. The parameter `Urls` takes a list of Urls, where the server will be hosted (default: `http://localhost:8080/`). The last parameter `HomeFile` maps the given file as default-mapping for each Url. `HttpSpawn` then returns a pair of an instance of `System.Net.HttpListener` and a url-mapper.

### Update Server
The server is not updated automatically. Instead this is done with `HttpTick`, which takes the aformentioned pair and updates the listener and handles GET,PUT,POST requests/resoneses in a ridiculusly direct fashion. There is also an explicit powershell injection for testing. Obviously this can be replaced with anything. This will also print the response in neat colors using deprecated `Write-Host`.

### Example

Using some test files in the Root-folder
```
cd Root
$h = HttpSpawn -HomeFile .\dynaChart.html
while(1){ HttpTick $h }
```
Type `Get-Random` to get a random number from the server-shell, click `Save` and test with `Update`.
The chart should update accordingly.
```
[400] GET(/current)
[400] GET(/favicon.ico)
[400] POST(/exec)
[200] PUT(/current, 'get-random')
[200] PUT(/current, 'get-random')
[200] PUT(/current, 'get-random')
[200] POST(/exec, 'current')
```