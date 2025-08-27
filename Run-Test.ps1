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
    # Exit silently on error
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
    # 1. Define file paths
    $smallTestFile = "E:\san_testfile_small.dat"
    $largeTestFile = "E:\san_testfile_large.dat"
    $smallResultFile = "E:\Results_SmallFile.txt"
    $largeResultFile = "E:\Results_LargeFile.txt"

    # 2. Run the disk tests and save results to files
    cmd /c "diskspd.exe -c40G -b1M -d10 -r -w100 -t8 -o64 -L -Sh -L -Zr -W0 $smallTestFile > $smallResultFile"
    cmd /c "diskspd.exe -c40G -b8k -d10 -r -w10 -t16 -o256 -L -Sh -L -Zr -W0 $largeTestFile > $largeResultFile"

    # 3. Read the content of the result files to send it back
    $result1 = Get-Content -Path $smallResultFile -Raw
    $result2 = Get-Content -Path $largeResultFile -Raw

    # 4. Clean up the files on the remote machine
    Remove-Item -Path $smallTestFile, $largeTestFile, $smallResultFile, $largeResultFile -Force

    # 5. Return the results
    return "$result1`n`n$result2"
}

# Invoke the command and capture the returned results
$finalResults = Invoke-Command -ComputerName $computerName -Credential $credential -ScriptBlock $scriptBlock

# Output the final results so the master script can display them
Write-Output $finalResults
