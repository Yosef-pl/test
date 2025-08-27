# --- Configuration ---
$computerName = "198.19.253.174"
$userName = "dcloud\demouser"
$plainTextPassword = "C1sco12345"

# --- Script Body ---
# Convert the plain text password to a Secure String
$securePassword = ConvertTo-SecureString -String $plainTextPassword -AsPlainText -Force

# Create the credential object
$credential = New-Object System.Management.Automation.PSCredential($userName, $securePassword)

# This is the command you want to run on the remote computer
$scriptBlock = {
    cmd /c "diskspd.exe -c40G -b1M -d10 -r -w100 -t8 -o64 -L -Sh -L -Zr -W0 E:\san_testfile_small.dat"
    cmd /c "diskspd.exe -c40G -b8k -d10 -r -w10 -t16 -o256 -L -Sh -L -Zr -W0 E:\san_testfile_large.dat"
}

# This command connects to the remote PC and runs the script block
Write-Host "Starting remote disk tests on $computerName..."
Invoke-Command -ComputerName $computerName -Credential $credential -ScriptBlock $scriptBlock

Write-Host "Remote commands have been launched successfully."
# This new line will keep the window open until you press Enter
Read-Host "Press ENTER to exit."