# --- DYNAMIC CONFIGURATION (Silent) ---
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
    exit
}

# --- STATIC CONFIGURATION ---
$userName = "dcloud\demouser"
$plainTextPassword = "C1sco12345"

# --- SCRIPT BODY ---
$securePassword = ConvertTo-SecureString -String $plainTextPassword -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($userName, $securePassword)

# This script block will run on the remote machine
$scriptBlock = {
    # Define the two test commands as PowerShell script blocks
    $script1 = {
        cmd /c "diskspd.exe -c40G -b1M -d10 -r -w100 -t8 -o64 -L -Sh -L -Zr -W0 E:\san_testfile_small.dat"
    }
    $script2 = {
        cmd /c "diskspd.exe -c40G -b8k -d10 -r -w10 -t16 -o256 -L -Sh -L -Zr -W0 E:\san_testfile_large.dat"
    }

    # Start both tests as parallel background jobs and hide their output objects
    $job1 = Start-Job -ScriptBlock $script1 | Out-Null
    $job2 = Start-Job -ScriptBlock $script2 | Out-Null

    # Wait for both jobs to complete
    Wait-Job -Job $job1, $job2

    # Clean up the jobs and test files from the remote machine
    Remove-Job -Job $job1, $job2 -Force
    Remove-Item -Path E:\san_testfile_*.dat -Force -ErrorAction SilentlyContinue

    # Return the simple success message
    return "The test completed successfully"
}

# Invoke the command and capture the returned message
$finalMessage = Invoke-Command -ComputerName $computerName -Credential $credential -ScriptBlock $scriptBlock

# Output the final message so the master script can display it
Write-Output $finalMessage
