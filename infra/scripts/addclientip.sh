#!/bin/bash
set -e

# Get environment values
output=$(azd env get-values)

# Parse the output to get the resource names, resource group, and VNet setting
EnableVirtualNetwork="false"
while IFS= read -r line; do
    if [[ $line == EVENTHUBS_CONNECTION__fullyQualifiedNamespace* ]]; then
        EventHubNamespace=$(echo "$line" | cut -d '=' -f 2 | tr -d '"' | sed 's/.servicebus.windows.net//')
    elif [[ $line == RESOURCE_GROUP* ]]; then
        ResourceGroup=$(echo "$line" | cut -d '=' -f 2 | tr -d '"')
    elif [[ $line == VNET_ENABLED* ]]; then
        EnableVirtualNetwork=$(echo "$line" | cut -d '=' -f 2 | tr -d '"')
    fi
done <<< "$output"

if [[ $EnableVirtualNetwork == "false" ]]; then
    echo "VNet is not enabled. Skipping adding the client IP to the network rule of the Event Hubs service"
else
    echo "VNet is enabled. Adding the client IP to the network rule of the Event Hubs service"
    
    # Get the client IP
    ClientIP=$(curl -s https://api.ipify.org)
 
  # Add the client IP to the network rule and mark the public network access as enabled since the client IP is added to the network rule
    az eventhubs namespace network-rule-set create --resource-group "$ResourceGroup" --namespace-name "$EventHubNamespace" --default-action "Deny" --public-network-access "Enabled" --ip-rules "[{action:Allow,ip-mask:$ClientIP}]" > /dev/null

fi
