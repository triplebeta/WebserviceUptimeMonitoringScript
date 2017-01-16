# WebserviceUptimeMonitoringScript
Script to monitor uptime of a webservice and sends Slack notification when it is down.
You may use this as a starting point for your own scripts.

##Features
- Supports self-signed SSL certificates
- Loads configuration from a json file
- Configure which headers to send to each service
- Runs on Azure Functions, config in Azure Blob Storage

##Todo
There are a few features I would still like to add:
  1.  store responses & timing
  2.  only send 1 message: when going DOWN and once when it's UP again
  3.  flag: stop reporting successful calls
  4.  aggregate all notifications of a pass into 1 post
