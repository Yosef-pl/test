# --- DYNAMIC CONFIGURATION ---
try {
    # 1. Read all settings from pods.txt into a lookup table
    # This script assumes pods.txt uses a simple 'key=value' format
    $podsTxtPath = 'C:\Scripts\pods.txt'
    $configData = Get-Content -Path $podsTxtPath -Raw | ConvertFrom-StringData
    
    # 2. Get the local Pod Name from the XML file
    $xmlPath = 'C:\dCloud\session.xml'
    $podName = (Select-Xml -Path $xmlPath -XPath '//device/name').Node.'#text'
    if (-not $podName) { throw "Pod name not found in $xmlPath" }
    
    # 3. Look up the IP address that matches the pod name
    $computerName = $configData[$podName]
    if (-not $computerName) { throw "IP for $podName not found in $podsTxtPath" }
}
catch {
    Write-Host "An error occurred during configuration:" -ForegroundColor Red
    Write-Host $_.Exception.Message
    Read-Host "Press ENTER to exit."
    exit
}

# --- TASK EXECUTION ---
Clear-Host
Write-Host "Pinging pod '$podName' at IP address $computerName..."
Write-Host "------------------------------------------------"

# Run the ping test (Test-Connection is the PowerShell version of ping)
Test-Connection -ComputerName $computerName -Count 4
    
# Keep the final output on screen until you press Enter
Read-Host "`nTest complete. Press ENTER to exit."
