# Azure Functions Python Event Hubs Trigger Sample

A Python Azure Functions QuickStart project demonstrating Event Hubs integration using Azure Developer CLI (azd). This sample showcases a real-time news streaming system with automated content generation and intelligent processing.

## Architecture

This architecture demonstrates how Azure Functions processes news articles through Event Hubs in real-time:

- **News Generator (Timer Trigger)**: Automatically generates realistic news articles every 10 seconds and streams them to Event Hubs
- **Azure Event Hubs**: Scalable messaging service handling high-throughput news streaming with 32 partitions
- **News Processor (Event Hub Trigger)**: Executes automatically when news articles arrive, performing sentiment analysis and engagement tracking
- **Azure Monitor**: Provides logging and metrics for function execution and news analytics

This serverless architecture enables highly scalable, event-driven news processing with built-in resiliency and automatic scaling.

## Features

* Event Hubs Trigger with high-throughput news streaming (180-270 articles/minute)
* Python Azure Functions (isolated worker model)
* Azure Functions Flex Consumption plan for automatic scaling
* Real-time sentiment analysis and engagement tracking
* Optional VNet integration with private endpoints for enhanced security
* Azure Developer CLI (azd) integration for easy deployment
* Infrastructure as Code using Bicep templates
* Comprehensive monitoring with Application Insights
* Managed Identity authentication for secure, passwordless access
* **Fixed table storage configuration** for Event Hub checkpointing
* **Fixed VNet detection logic** in deployment scripts

## Prerequisites

- [Python 3.13](https://www.python.org/downloads/) or later
- [Azure Functions Core Tools](https://docs.microsoft.com/azure/azure-functions/functions-run-local#install-the-azure-functions-core-tools) v4.x
- [Azure Developer CLI (azd)](https://docs.microsoft.com/azure/developer/azure-developer-cli/install-azd)
- [Azurite](https://github.com/Azure/Azurite) for local development
- An Azure subscription

## Quickstart

### 1. Clone and Navigate

```bash
git clone <your-repo-url>
cd eventhubs-python
```

### 2. Set Execution Policy (Windows)

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Mac/Linux:
```bash
chmod +x ./infra/scripts/*.sh
```

### 3. Configure VNet Settings (Optional)

**For simple deployment without VNet:**
```bash
azd env set VNET_ENABLED false
```

**For secure deployment with VNet:**
```bash
azd env set VNET_ENABLED true
```

> **Note:** If you don't set `VNET_ENABLED`, the deployment will use `false` by default.

### 4. Provision Azure Resources

```bash
azd provision
```

This creates:
- Azure Event Hubs namespace and hub (32 partitions)
- Azure Function App (Flex Consumption, Python 3.13)
- Application Insights for monitoring
- Storage Account with **table storage enabled** for Event Hub checkpointing
- Virtual Network with private endpoints (if `VNET_ENABLED=true`)
- `local.settings.json` for local development

### 5. Test Locally

Start Azurite:
```bash
azurite
```

In a new terminal, run the function:
```bash
func start
```

You should see console output with news generation and processing:
```
[2024-11-10T10:30:15.123Z] ✅ HIGH-THROUGHPUT: Successfully generated 5 news articles in ~10 seconds
[2024-11-10T10:30:15.145Z] ✅ Successfully processed article NEWS-20241110-A1B2C3D4 - 'Breaking News...' by Sarah Johnson
[2024-11-10T10:30:15.147Z] 🔥 Viral article: NEWS-20241110-E5F6G7H8 - 8,547 views
[2024-11-10T10:30:15.149Z] 📊 NEWS BATCH SUMMARY: 5 articles | Total Views: 18,432 | Avg Sentiment: 0.34
```

### 6. Deploy to Azure

```bash
azd deploy
```

### 7. Monitor in Azure

- Navigate to your Function App in Azure Portal
- Go to Functions → Monitor tab
- Check Application Insights Live Metrics for real-time processing

## Understanding the Code

### News Generator (Timer Trigger)

Runs every 10 seconds generating 3-8 realistic news articles:

```python
@app.timer_trigger(schedule="0,10,20,30,40,50 * * * * *", arg_name="timer")
@app.event_hub_output(arg_name="event", event_hub_name="news", connection="EventHubConnection")
def NewsGenerator(timer: func.TimerRequest, event: func.Out[str]) -> None:
    # Generate articles and send to Event Hub
```

### News Processor (Event Hub Trigger)

Triggered automatically when articles arrive:

```python
@app.event_hub_message_trigger(arg_name="events", event_hub_name="news",
                                connection="EventHubConnection")
def EventHubsTrigger(events: List[func.EventHubEvent]):
    # Process articles with sentiment analysis
```

## Project Structure

```
eventhubs-python/
├── function_app.py             # Azure Functions with triggers
├── host.json                   # Function host settings
├── requirements.txt            # Python dependencies
├── local.settings.json         # Local development settings (generated)
├── infra/                      # Infrastructure as Code
│   ├── main.bicep             # Main infrastructure template
│   ├── main.parameters.json   # Infrastructure parameters
│   ├── abbreviations.json     # Resource naming abbreviations
│   ├── app/                   # Modular infrastructure components
│   │   ├── api.bicep          # Function App (Flex Consumption)
│   │   ├── eventhubs.bicep    # Event Hubs namespace and hub
│   │   ├── rbac.bicep         # Role-based access control
│   │   ├── vnet.bicep         # Virtual Network configuration
│   │   ├── eventhubs-PrivateEndpoint.bicep
│   │   └── storage-PrivateEndpoint.bicep
│   └── scripts/               # Deployment and setup scripts
│       ├── postprovision.ps1  # Post-provision setup (Windows)
│       ├── postprovision.sh   # Post-provision setup (POSIX)
│       ├── addclientip.ps1    # Add client IP to Event Hubs (Windows)
│       └── addclientip.sh     # Add client IP to Event Hubs (POSIX)
├── .github/
│   └── copilot-instructions.md
├── azure.yaml                  # Azure Developer CLI configuration
└── README.md                   # This file
```

## Configuration

### Event Hub Connection

The connection uses managed identity (passwordless):
```json
{
  "EventHubConnection__fullyQualifiedNamespace": "your-namespace.servicebus.windows.net"
}
```

### VNet Integration

When `VNET_ENABLED=true`, the deployment creates:
- Virtual Network with three subnets
- Private endpoints for Storage (blob, table) and Event Hubs
- Private DNS zones for name resolution
- Network isolation with public access disabled

## Troubleshooting

### Event Hub Trigger Not Working

1. **Check Table Storage**: Ensure table storage is enabled (already fixed in this version)
2. **Check Network Rules**: If VNet is disabled, ensure Event Hubs allows public access
3. **Check RBAC**: Verify managed identity has Event Hubs Data Receiver and Data Sender roles

### Local Development Issues

- Ensure Azurite is running before starting functions
- Check `local.settings.json` has correct Event Hub namespace
- Verify you have Event Hubs Data Receiver/Sender roles on the namespace

## Key Fixes in This Version

1. ✅ **Table Storage Enabled**: Event Hub triggers require table storage for checkpointing
2. ✅ **Fixed VNet Detection**: Scripts now correctly read `VNET_ENABLED` from environment variables
3. ✅ **Network Firewall Logic**: Proper handling of network rules based on VNet configuration

## Resources

- [Azure Functions Python Developer Guide](https://docs.microsoft.com/azure/azure-functions/functions-reference-python)
- [Azure Event Hubs Documentation](https://docs.microsoft.com/azure/event-hubs/)
- [Azure Developer CLI Documentation](https://docs.microsoft.com/azure/developer/azure-developer-cli/)
- [Azure Functions Flex Consumption Plan](https://docs.microsoft.com/azure/azure-functions/flex-consumption-plan)

## License

This sample is provided as-is under the MIT License.
