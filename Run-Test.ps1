# B------------------------------------------------------------------------------
# Script: Run-Test.ps1
# Description: This script identifies the current pod from session.xml,
#              finds its IP from pods.txt, and pings the remote IP address.
#------------------------------------------------------------------------------

# --- 1. Define File Paths and Validate Their Existence ---
Write-Host "Initializing script and validating file paths..."
$sessionXmlPath = "C:\dcloud\session.xml"
$podDataPath = "C:\Scripts\pods.txt"

# Check if the session file exists
if (-not (Test-Path $sessionXmlPath)) {
    Write-Error "CRITICAL: Session file not found at '$sessionXmlPath'. Cannot determine which pod to test. Exiting."
    exit
}

# Check if the pod data file exists
if (-not (Test-Path $podDataPath)) {
    Write-Error "CRITICAL: Pod data file not found at '$podDataPath'. Cannot find IP addresses. Exiting."
    exit
}
Write-Host "✅ Files validated successfully."
Write-Host "" # New line for spacing

# --- 2. Read the Target Pod Name from the Session XML File ---
Write-Host "Reading target pod name from session file..."
try {
    # Cast the file content to XML and get the pod name
    # This assumes the XML structure is <session><pod>pod-name</pod></session> or similar
    [xml]$xmlContent = Get-Content -Path $sessionXmlPath
    $podNameToFind = $xmlContent.SelectSingleNode("//pod").'#text' # Selects the first <pod> node's text

    if ([string]::IsNullOrWhiteSpace($podNameToFind)) {
        Write-Error "CRITICAL: Could not find a pod name inside '$sessionXmlPath'. Please check the XML file format. Exiting."
        exit
    }
    Write-Host "✅ Pod to find: $podNameToFind"
    Write-Host "" # New line for spacing
}
catch {
    Write-Error "CRITICAL: Failed to read or parse the XML file at '$sessionXmlPath'. Error: $_"
    exit
}

# --- 3. Parse pods.txt to Find the Corresponding IP Address ---
Write-Host "Searching for '$podNameToFind' in the pod data file..."
$ipAddress = $null # Initialize variable to store the IP

# Get content from pods.txt, ignore comments (#) and empty lines, and find the matching entry
Get-Content $podDataPath | ForEach-Object {
    $line = $_.Trim()
    if ($line -and !$line.StartsWith("#")) {
        $key, $value = $line.Split("=", 2)
        if ($key.Trim() -eq $podNameToFind) {
            $ipAddress = $value.Trim()
        }
    }
}

# Check if an IP was found
if (-not $ipAddress) {
    Write-Error "CRITICAL: Could not find an IP address for '$podNameToFind' in '$podDataPath'. Exiting."
    exit
}
Write-Host "✅ Found IP Address: $ipAddress"
Write-Host "" # New line for spacing

# --- 4. Ping the Remote IP Address ---
Write-Host "🎯 Pinging remote host at $ipAddress..."
Write-Host "------------------------------------------------"
try {
    # Use Test-Connection, which is the PowerShell equivalent of ping
    Test-Connection -ComputerName $ipAddress -Count 4 -ErrorAction Stop
    Write-Host "------------------------------------------------"
    Write-Host "✅ Ping test completed successfully."
}
catch {
    Write-Error "Ping test failed. The host at $ipAddress may be unreachable. Error: $_"
}
