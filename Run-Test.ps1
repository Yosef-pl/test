# --- DYNAMIC CONFIGURATION ---
# This section automatically finds the correct IP address based on local files.
Write-Host "Determining local pod and IP address..."
try {
    # 1. Get the Pod Name from the XML file
    $xmlPath = 'C:\dCloud\session.xml'
    $podName = (Select-Xml -Path $xmlPath -XPath '//device/name').Node.'#text'
    if (-not $podName) { throw "Pod name not found in $xmlPath" }
    Write-Host "Found Pod Name: $podName"

    # 2. Build a lookup table from the pods.txt file
    $podsTxtPath = 'C:\Scripts\pods.txt'
    # Read the file and create a searchable hashtable (e.g., @{'dcv-mds-pod1'='198.19.253.171'})
    $ipLookup = @{}
    Get-Content $podsTxtPath | ForEach-Object {
        # This removes the 'set "' and '"' parts and splits the line into a key and value
        if ($_ -match 'set "(.*)=(.*)"') {
            $key = $matches[1]
            $value = $matches[2]
            $ipLookup[$key] = $value
        }
    }
    
    # 3. Find the IP that matches the Pod Name
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
# Convert the plain text password to a Secure String
$securePassword = ConvertTo-SecureString -String $plainTextPassword -AsPlainText -Force

# Create the credential object
$credential = New-Object System.Management.Automation.PSCredential($userName, $securePassword)

# This is the command you want to run on the remote computer
$scriptBlock = {
    # The '> NUL 2>&1' part hides all output from the diskspd command
    cmd /c "diskspd.exe -c40G -b1M -d10 -r -w100 -t8 -o64 -L -Sh -L -Zr -W0 E:\san_testfile_small.dat > NUL 2>&1"
    cmd /c "diskspd.exe -c40G -b8k -d10 -r -w10 -t16 -o256 -L -Sh -L -Zr -W0 E:\san_testfile_large.dat > NUL 2>&1"
}

# This command connects to the remote PC and runs the script block
Write-Host "Starting remote disk tests on $computerName..."
Invoke-Command -ComputerName $computerName -Credential $credential -ScriptBlock $scriptBlock

# Display the custom message after launching the commands
Write-Host "The test is now running."
# This new line will keep the window open until you press Enter
Read-Host "Press ENTER to exit."
