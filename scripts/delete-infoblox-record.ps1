# Infoblox Delete A/AAAA Record Script

# Prompt for Infoblox details
$InfobloxServer = "https://infoblox.example.com/wapi/v2.9"
$Username = Read-Host "Enter Infoblox username"
$Password = Read-Host "Enter Infoblox password" -AsSecureString
$Credential = New-Object System.Management.Automation.PSCredential ($Username, $Password)

# Prompt for record or IP
$InputValue = Read-Host "Enter the DNS record name or IP address to delete"
$TicketNumber = Read-Host "Enter the ticket number for tracking"

# Search for A and AAAA records
$ARecordUri = "$InfobloxServer/record:a?name~=$InputValue|ipv4addr~=$InputValue"
$AAAARecordUri = "$InfobloxServer/record:aaaa?name~=$InputValue|ipv6addr~=$InputValue"

Write-Host "Searching for A records..."
$ARecords = Invoke-RestMethod -Uri $ARecordUri -Credential $Credential -Method Get -SkipCertificateCheck
Write-Host "Searching for AAAA records..."
$AAAARecords = Invoke-RestMethod -Uri $AAAARecordUri -Credential $Credential -Method Get -SkipCertificateCheck

if ($ARecords.Count -eq 0 -and $AAAARecords.Count -eq 0) {
    Write-Host "No matching A or AAAA records found."
    exit
}

Write-Host "Found the following records:"
if ($ARecords) { Write-Host "`nA Records:"; $ARecords | Format-Table name, ipv4addr }
if ($AAAARecords) { Write-Host "`nAAAA Records:"; $AAAARecords | Format-Table name, ipv6addr }

$Confirm = Read-Host "Do you want to delete these records? (Y/N)"
if ($Confirm -ne "Y") {
    Write-Host "Aborted by user."
    exit
}

# Delete records
foreach ($Record in $ARecords) {
    Write-Host "Deleting A record: $($Record.name) $($Record.ipv4addr)"
    Invoke-RestMethod -Uri "$InfobloxServer/$($Record._ref)" -Credential $Credential -Method Delete -SkipCertificateCheck
}
foreach ($Record in $AAAARecords) {
    Write-Host "Deleting AAAA record: $($Record.name) $($Record.ipv6addr)"
    Invoke-RestMethod -Uri "$InfobloxServer/$($Record._ref)" -Credential $Credential -Method Delete -SkipCertificateCheck
}

Write-Host "Deletion complete. Ticket number $TicketNumber logged for tracking."
