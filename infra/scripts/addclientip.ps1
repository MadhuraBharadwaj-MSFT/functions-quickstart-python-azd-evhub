$ErrorActionPreference = "Stop"

$output = azd env get-values

# Parse the output to get the resource names, resource group, and VNet setting
$VnetEnabled = $false
foreach ($line in $output) {
    if ($line -match "EVENTHUBS_CONNECTION__fullyQualifiedNamespace"){
        $EventHubNamespace = ($line -split "=")[1] -replace '"','' -replace '.servicebus.windows.net',''
    }
    if ($line -match "RESOURCE_GROUP"){
        $ResourceGroup = ($line -split "=")[1] -replace '"',''
    }
    if ($line -match "^VNET_ENABLED="){
        $VnetEnabledValue = ($line -split "=")[1] -replace '"',''
        $VnetEnabled = $VnetEnabledValue -eq "true"
    }
}

if ($VnetEnabled -eq $false) {
    Write-Output "VNet is not enabled. Skipping adding the client IP to the network rule of the Event Hubs service"
}
else {
    Write-Output "VNet is enabled. Adding the client IP to the network rule of the Event Hubs service"
    
    # Get the client IP
    $ClientIP = Invoke-RestMethod -Uri 'https://api.ipify.org'
    
    # Get current network rule set
    $NetworkRuleSet = az eventhubs namespace network-rule-set show --resource-group $ResourceGroup --namespace-name $EventHubNamespace | ConvertFrom-Json
    $IPExists = $false
    
    if ($NetworkRuleSet.ipRules) {
        foreach ($Rule in $NetworkRuleSet.ipRules) {
            if ($Rule.ipMask -eq $ClientIP) {
                $IPExists = $true
                break
            }
        }
    }
    
    if ($false -eq $IPExists) {
        Write-Output "Adding the client IP $ClientIP to the network rule of the Event Hubs service $EventHubNamespace"
        az eventhubs namespace network-rule-set create --resource-group $ResourceGroup --namespace-name $EventHubNamespace --default-action "Deny" --public-network-access "Enabled" --ip-rules "[{action:Allow,ip-mask:$ClientIP}]" | Out-Null
    }
    else {
        Write-Output "The client IP $ClientIP is already in the network rule of the Event Hubs service $EventHubNamespace"
    }
}
