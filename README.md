# Webservice Uptime Monitoring Script
Powershell script to monitor uptime of a webservice and sends Slack notification when it is down.
You may use this as a starting point for your own scripts.

##Features
- Supports self-signed SSL certificates
- Loads configuration from a json file
- Reports duration of the monitoring call
- Configure which headers to send to each service
- Runs on Azure Functions, config in Azure Blob Storage

Requires Powershell 3+.

##Usage
The script uses th SitesToCheck variable to find the configuration file containing its configuration information. An example is available  available in config.json file. Each of these urls is checked once. To get access to Slack it reads the SlackApiToken environment variable. 

##Getting started 
Serverless computing like [Azure Functions](https://azure.microsoft.com/services/functions/) is very well suited for running jobs like these. Even the free tier offers more than enough resources to run the monitoring script and is fairly easy to setup in a few minutes.
Here's how to setup the monitoring job in your Azure account:
  1.  Acquire a token for testing to allow posting to Slack, from: [Slack Tokens for testing and Development](https://api.slack.com/docs/oauth-test-tokens)
  2.  Create a free or paid account on [Microsoft Azure](https://azure.microsoft.com/free/)
  3.  Create a new Function App
  4.  Add a new Function, in the language menu choose PowerShell and choose the TimerTrigger-Powershell template
  5.  On the Development tab replace the text with the full content of the WebserviceUptimeMonitoringScript.ps1 file
  6.  On the Integrate tab click Add Input and choose Azure Storage File
  7.  Configure a connection to the Azure Storage account where you plan to store the configuration file
  8.  Go to the Function App Settings at the bottom, choose "Configure app setting", in the App settings you add a new key named SlackApiToken and set its value to the key you retrieved from Slack.
  9.  On th Manage tab, make sure the job is enabled.

And you're good to go!

##Todo
There are a few features I would still like to add:
  1.  store responses & timing
  2.  only send 1 message: when going DOWN and once when it's UP again
  3.  flag: stop reporting successful calls
  4.  aggregate all notifications of a pass into 1 post
