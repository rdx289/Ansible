# Description: This script retrieves registered applications from Microsoft Graph API and checks their password expiry dates.
# It sends a notification via a webhook if the password is set to expire within 91 days.

$tenantId = "5a60d899-28b4-48b9-a5a9-eec8372021de"
$clientId = "dbd56c67-fb60-4c76-a4d9-48ed52474172"
$clientSecret = "VUv8Q~zU2E-8.BWVhxcMqASbcLFUVj9FZc6Beb5Y"

# Main script
$body = @{
    grant_type    = "client_credentials"
    client_id     = $clientId
    client_secret = $clientSecret
    scope         = "https://graph.microsoft.com/.default"
}

$tokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" -Method Post -Body $body
$accessToken = $tokenResponse.access_token

# Get registered apps
$headers = @{
    Authorization = "Bearer $accessToken"
    "Content-Type" = "application/json"
}

$graphUrl = "https://graph.microsoft.com/v1.0/applications"
$appData = Invoke-RestMethod -Uri $graphUrl -Headers $headers -Method Get

# Get current date
$today = Get-Date

$webhookUrl = "https://prod-12.westus.logic.azure.com:443/workflows/b1f0d40b084d44ffa04b2747541d5c8e/triggers/manual/paths/invoke?api-version=2016-06-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=VDoLSyVfRHScodWiyl5WvrcZiWI6hjWoDpHAGyzpAkA"

# Process app data
$appData.value | ForEach-Object {
    $expiryDate = if ($_.passwordCredentials -and $_.passwordCredentials[0].endDateTime) { 
        [DateTime]::Parse($_.passwordCredentials[0].endDateTime) 
    } else { 
        $null 
    }

    if ($expiryDate) {
        $daysUntilExpiry = [math]::Round(($expiryDate - $today).TotalDays)

        if ($daysUntilExpiry -le 30) {

            
            $appDetails = @{
                AppName         = $_.displayName
                PublisherDomain = $_.publisherDomain
                ID              = $_.id
                AppID           = $_.appId
                CreatedDate     = (Get-Date $_.createdDateTime -Format "dd-MM-yyyy")
                ExpiryDate      = $expiryDate.ToString("dd-MM-yyyy")
                DaysUntilExpiry = $daysUntilExpiry
            }

            # Convert to JSON and output
            $appDetailsJson = $appDetails | ConvertTo-Json -Depth 2
            Write-Host "Body: $appDetailsJson"

            Invoke-WebRequest -Uri $webhookUrl -Method Post -Body $appDetailsJson -ContentType "application/json" -Headers @{
                "Content-Type" = "application/json"
            } | Out-Null

        }
    }
}