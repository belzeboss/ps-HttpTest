# Code collected scripts in X:\Coding\ps\modules\HttpModule

function HttpSpawn
{
    param(
        [string[]]$Urls = ("http://localhost:8080/"),
        [string]$Root = "$pwd",
        [string]$HomeFile)
    $listener = [System.Net.HttpListener]::new()
    $Urls | % { $listener.Prefixes.Add($_) }

    $Root = [System.IO.Path]::TrimEndingDirectorySeparator((Resolve-Path $Root).Path)
    $map = [System.Collections.Generic.Dictionary[string, string]]::new()
    if ("$HomeFile".Length -gt 0) {
        $map["/"] = (Resolve-Path $HomeFile).Path
    }
    gci $Root -Recurse -File | % {
        $rel = $_.FullName.Substring($Root.Length) -replace "\\", "/"
        $map[$rel] = $_.FullName
        Write-Host "Map $rel"
    }
    $listener.Start()
    [object[]]($listener, $map)
}

function HttpTick
{
    param([Parameter(ValueFromPipeline = $true, Mandatory = $true)]$HttpMapPair)
    [System.Net.HttpListener]$listener = $HttpMapPair[0]
    [System.Collections.Generic.Dictionary[string, string]]$UrlMapper = $HttpMapPair[1]

    $c = $listener.GetContext()

    function respond($Code, $Name = "Error", $buf = [byte[]]::new(0), $ContentType) {
        $c.Response.ContentType = "$ContentType; charset=utf-8"
        $c.Response.ContentEncoding = [System.Text.Encoding]::UTF8
        $c.Response.StatusCode = $Code
        $c.Response.StatusDescription = $Name

        $c.Response.ContentLength64 = $buf.Length
        $c.Response.OutputStream.Write($buf, 0, $buf.Length)
        $c.Response.OutputStream.Close()
    }

    switch ($c.Request.HttpMethod) {
        "Get" {
            [string]$value = ""
            if ($UrlMapper.TryGetValue($c.Request.RawUrl, [ref]$value)) {
                if (Test-Path $value -PathType Leaf) {
                    $type = [System.IO.Path]::GetExtension($value)
                    $type = if ($type -eq "js") {
                        "javascript"
                    }
                    else {
                        "html"
                    }
                    respond 200 "File-Fetch" ([System.IO.File]::ReadAllBytes($value)) "text/$type"
                }
                else {
                    respond 200 "Direct-Fetch" ([System.Text.Encoding]::UTF8.GetBytes($value)) "text/javascript"
                }
            }
            elseif ($UrlMapper.TryGetValue("//$($c.Request.RawUrl)", [ref]$value)) {
                respond 200 "Value-Fetch" ([System.Text.Encoding]::UTF8.GetBytes($value)) "text/javascript"
            }
            else {
                respond 400
            }
            $params = $value
        }
        "Put" {
            $putData = [System.IO.StreamReader]::new($c.Request.InputStream).ReadToEnd()
            try {
                $obj = ConvertFrom-Json $putData
            }
            catch {
                $obj = "$putData"
            }
            $UrlMapper["//$($c.Request.RawUrl)"] = $obj
            respond 200 "Value-Put" -ContentType "text/javascript"
            $params = "$obj"
        }
        "Post" {
            #$query = [System.Web.HttpUtility]::ParseQueryString($uri.Query)
            $postData = [System.IO.StreamReader]::new($c.Request.InputStream).ReadToEnd()
            switch ($c.Request.RawUrl) {
                "/exec" {
                    $cmd = $UrlMapper["///$postData"]
                    if ("$cmd".Length -gt 0) {
                        $block = [scriptblock]::Create($cmd)
                        $response = Invoke-Command -scriptblock $block | ConvertTo-Json -Depth 3
                        $buf = [system.Text.encoding]::Utf8.GetBytes("$response")
                        respond 200 "Exec-Response" $buf "application/json"
                        $params = $postData
                    }
                    else {
                        respond 400    
                    }
                }
                default {
                    respond 400
                }
            }
            # ping 8.8.8.8 -n 1 | sls "time=(\d+)ms" | %{$_.Matches.Groups[1].Value}
            # Get-Random
        }
    }
    Write-Host "[" -NoNewLine
    if ($c.Response.StatusCode -eq 200) {
        Write-Host $c.Response.StatusCode -f Green -NoNewLine
    }
    else {
        Write-Host $c.Response.StatusCode -f Red -NoNewLine
    }
    Write-Host "] $($c.Request.HttpMethod)(" -NoNewLine
    write-host $c.Request.RawUrl -f Cyan -NoNewLine
    if ("$params".Length -gt 0) {
        Write-Host ", " -NoNewLine
        write-host "'$params'" -f Cyan -NoNewLine
    }
    Write-Host ")"
}
