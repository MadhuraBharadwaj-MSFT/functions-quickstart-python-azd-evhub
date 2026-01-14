#!/bin/bash
set -e

echo "Deployment completed successfully!"
echo ""

# Get the outputs from the deployment
output=$(azd env get-values)

# Parse outputs
while IFS= read -r line; do
    if [[ $line == EVENTHUBS_CONNECTION__fullyQualifiedNamespace* ]]; then
        EventHubsNamespace=$(echo "$line" | cut -d '=' -f 2 | tr -d '"')
    elif [[ $line == SERVICE_API_NAME* ]]; then
        SERVICE_API_NAME=$(echo "$line" | cut -d '=' -f 2 | tr -d '"')
    fi
done <<< "$output"

echo "News Streaming System deployed successfully!"
echo ""
echo "System components:"
echo "  - News Generator Function: Generates 3-8 news articles every 10 seconds"
echo "  - News Processor Function: Processes articles from Event Hub with sentiment analysis"
echo "  - Event Hub: news"
echo "  - Event Hubs Namespace: $EventHubsNamespace"
echo ""
echo "Both functions are now running in Azure!"
echo ""
echo "To monitor the system:"
echo "  1. View Function App logs in Azure Portal"
echo "  2. Check Application Insights for real-time metrics"
echo "  3. Monitor Event Hub message flow (32 partitions)"
echo ""
echo "Expected behavior:"
echo "  - News Generator creates 3-8 realistic articles every 10 seconds"
echo "  - News Processor analyzes sentiment and detects viral content"
echo "  - View processing logs with emojis in Azure Portal"
echo "  - High throughput: ~180-270 articles/minute"
echo ""
echo "Function App Name: $SERVICE_API_NAME"

echo "Creating/updating local.settings.json..."

cat > ./local.settings.json << EOF
{
  "IsEncrypted": "false",
  "Values": {
    "AzureWebJobsStorage": "UseDevelopmentStorage=true",
    "FUNCTIONS_WORKER_RUNTIME": "python",
    "EventHubConnection__fullyQualifiedNamespace": "$EventHubsNamespace"
  }
}
EOF

echo "local.settings.json has been created/updated successfully!"
