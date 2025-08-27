# --- USER INTERFACE AND SCRIPT BODY ---
# This script is now self-contained. It handles all user messages and actions.

# 1. Clear the screen and display the status message
Clear-Host
Write-Host "The test is now running, it will finish after 5 minutes..."

# 2. Dynamically find the target computer's IP address
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

# 3. Define credentials
$userName = "dcloud\demouser"
$plainTextPassword = "C1sco12345"
$securePassword = ConvertTo-SecureString -String $plainTextPassword -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($userName, $securePassword)

# 4. Define the remote commands
$scriptBlock = {
    # Define file paths
    $smallTestFile = "E:\san_testfile_small.dat"
    $largeTestFile = "E:\san_testfile_large.dat"
    $smallResultFile = "E:\Results_SmallFile.txt"
    $largeResultFile = "E:\Results_LargeFile.txt"

    # Run the disk tests for 5 minutes (-d300) and save results
    cmd /c "diskspd.exe -c40G -b1M -d300 -r -w100 -t8 -o64 -L -Sh -L -Zr -W0 $smallTestFile > $smallResultFile"
    cmd /c "diskspd.exe -c40G -b8k -d300 -r -w10 -t16 -o256 -L -Sh -L -Zr -W0 $largeTestFile > $largeResultFile"

    # Read the content of the result files to send it back
    $result1 = Get-Content -Path $smallResultFile -Raw
    $result2 = Get-Content -Path $largeResultFile -Raw

    # Clean up the files on the remote machine
    Remove-Item -Path $smallTestFile, $largeTestFile, $smallResultFile, $largeResultFile -Force

    # Return the results
    return "$result1`n`n$result2"
}

# 5. Run the remote command and capture the output
$finalResults = Invoke-Command -ComputerName $computerName -Credential $credential -ScriptBlock $scriptBlock

# 6. Clear the "test is running" message and display the final results
Clear-Host
Write-Output $finalResults
