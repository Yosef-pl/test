# --- DYNAMIC CONFIGURATION ---
Write-Host "Determining local pod and IP address..."
try {
    $xmlPath = 'C:\dCloud\session.xml'
    $podName = (Select-Xml -Path $xmlPath -XPath '//device/name').Node.'#text'
    if (-not $podName) { throw "Pod name not found in $xmlPath" }
    Write-Host "Found Pod Name: $podName"

    $podsTxtPath = 'C:\Scripts\pods.txt'
    $ipLookup = @{}
    Get-Content $podsTxtPath | ForEach-Object {
        if ($_ -match 'set "(.*)=(.*)"') {
            $key = $matches[1]
            $value = $matches[2]
            $ipLookup[$key] = $value
        }
    }
    
    $computerName = $ipLookup[$podName]
    if (-not $computerName) { throw "IP for $podName not found in $podsTxtPath" }
    Write-Host "Found matching IP: $computerName"
}
catch {
    Write-Host "Error during automatic configuration: $($_.Exception.Message)"
    Read-Host "Press ENTER to exit."
    exit
}

# --- STATIC CONFIGURATION ---
$userName = "dcloud\demouser"
$plainTextPassword = "C1sco12345"

# --- SCRIPT BODY ---
$securePassword = ConvertTo-SecureString -String $plainTextPassword -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($userName, $securePassword)

$scriptBlock = {
    # The '> NUL 2>&1' part hides all output from the diskspd command
    cmd /c "diskspd.exe -c40G -b1M -d10 -r -w100 -t8 -o64 -L -Sh -L -Zr -W0 E:\san_testfile_small.dat > NUL 2>&1"
    cmd /c "diskspd.exe -c40G -b8k -d10 -r -w10 -t16 -o256 -L -Sh -L -Zr -W0 E:\san_testfile_large.dat > NUL 2>&1"
}

Write-Host "Starting remote disk tests on $computerName..."
Invoke-Command -ComputerName $computerName -Credential $credential -ScriptBlock $scriptBlock

Write-Host "The test is now running."
Read-Host "Press ENTER to exit."


