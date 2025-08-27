# --- REMOTE JOB STARTER SCRIPT ---
# This script's job is to configure and start the remote test, then hand off control.

# 1. Dynamically find the target computer's IP address
try {
    $xmlPath = 'C:\dCloud\session.xml'
    $podName = (Select-Xml -Path $xmlPath -XPath '//device/name').Node.'#text'
    if (-not $podName) { throw "Pod name not found in $xmlPath" }

    $podsTxtPath = 'C:\Scripts\pods.txt'
    $ipLookup = @{}
    Get-Content $podsTxtPath | ForEach-Object {
        if ($_ -match 'set "(.*)=(.*)"') {
            $ipLookup[$matches[1]] = $matches[2]
        }
    }
    
    $computerName = $ipLookup[$podName]
    if (-not $computerName) { throw "IP for $podName not found in $podsTxtPath" }
}
catch {
    Write-Host "Error during automatic configuration: $($_.Exception.Message)"
    exit
}

# 2. Define credentials
$userName = "dcloud\demouser"
$plainTextPassword = "C1sco12345"
$securePassword = ConvertTo-SecureString -String $plainTextPassword -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($userName, $securePassword)

# 3. Define the remote commands
$scriptBlock = {
    $smallTestFile = "E:\san_testfile_small.dat"
    $largeTestFile = "E:\san_testfile_large.dat"
    
    cmd /c "diskspd.exe -c40G -b1M -d10 -r -w100 -t8 -o64 -L -Sh -L -Zr -W0 $smallTestFile"
    Start-Sleep -Seconds 5
    cmd /c "diskspd.exe -c40G -b8k -d10 -r -w10 -t16 -o256 -L -Sh -L -Zr -W0 $largeTestFile"
}

# 4. Create a session, start the job, and return the management objects
$session = New-PSSession -ComputerName $computerName -Credential $credential
$job = Invoke-Command -Session $session -ScriptBlock $scriptBlock -AsJob

# Return both the session and the job so the master script can control them
return [PSCustomObject]@{
    Session = $session
    Job = $job
}

