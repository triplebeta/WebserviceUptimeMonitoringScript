#Requires -Version 3.0
Set-StrictMode -Version Latest
#
# Check webservice or website availability and report problems to a slack channel.
# Parameters:
#   SlackApiToken	Token to allow posting on a Slack channel
#   SitesToCheck	Json describing the sites to test
#
# Features:
#   Can run on Azure Functions (see azure.json)
#   Read configuration from Azure Blob Storate
#   Send headers with the requests
#   Support self-signed certificates
#   Notify of downtime via Slack
#
# Limitations:
#   Assumes every url returns json

if ((Get-Variable ConfigJsonFile -ErrorAction SilentlyContinue))
{
	Write-Output "Using configuration from parameter ConfigJsonFile parameter."
	Write-Output "Loading config from: $ConfigJsonFile"
}
else
{
	$ConfigJsonFile = $(PSScriptRoot) + '\Config.json'
	Write-Output "No parameter ConfigJsonFile found, defaulting to local file: $ConfigJsonFile"
}

# Secrets to read from vault
$slackApiToken = $env:SlackApiToken
$SitesToCheck = Get-Content -Raw -Path $ConfigJsonFile

$slackBotName = "Uptime monitor"
$requestTimeout = 15  #seconds


Add-Type @"
    using System;
    using System.Net;
    using System.Net.Security;
    using System.Security.Cryptography.X509Certificates;
    public class ServerCertificateValidationCallback
    {
        public static void Ignore()
        {
            ServicePointManager.ServerCertificateValidationCallback += 
                delegate
                (
                    Object obj, 
                    X509Certificate certificate, 
                    X509Chain chain, 
                    SslPolicyErrors errors
                )
                {
                    return true;
                };
        }
    }
"@
[ServerCertificateValidationCallback]::Ignore();


# Check 1 specific site. Must be declared BEFORE it's invoked
Function Check-SiteIsUp($site)
{
	Try
	{
		$elapsed = Measure-Command {
			if ($site.headers -ne {null}) {
				$hash = @{};
				$site.headers | Get-Member -MemberType *Property | % {  $hash.($_.name) = $site.headers.($_.name);  }
				
				$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
				Foreach($k in $hash.Keys)
				{
					$value = $hash.Get_Item($k)
					$headers.Add($k, $value)
				}
				$response = Invoke-RestMethod -Method Get -Uri $site.url -ContentType application/json -Headers $headers -TimeoutSec $requestTimeout
			}
			else
			{
				$response = Invoke-RestMethod -Method Get -Uri $site.url -ContentType application/json -TimeoutSec 15
			}
		}
		$errorMessage = "Checking " + $site.name + ": OK ($($elapsed.Milliseconds)ms)"
	}
	Catch [System.Net.WebException]
	{
		$errorCode = $_.Exception.Response.StatusCode
		if ($errorCode -eq "Forbidden") { $errorMessage=$site.name + ": 403 Forbidden " } 
		if ($errorCode -eq "Unauthorized") { $errorMessage=$site.name + ": 401 Unauthorized" }
	}
	Catch [System.Exception]
	{
		$errorMessage = "Unexpected problem checking the uptime" + $_.Exception
	}
	return $errorMessage
}


# Process all sites
$sites = ConvertFrom-Json $SitesToCheck
Foreach ($site in $sites)
{
	#Test availability, returns a message
	$result = Check-SiteIsUp($site)

	#Notify via Slack
	if ($result -ne {null} -and $slackApiToken -ne {null} -and $site.slackChannel -ne {null})
	{
		$postSlackMessage = @{
			token=$slackApiToken;
			channel=$site.slackChannel;
			text=$result;
			username=$slackBotName
		}
		$slackResponse=Invoke-RestMethod -Uri https://slack.com/api/chat.postMessage -Body $postSlackMessage -TimeoutSec $requestTimeout
	}
}

