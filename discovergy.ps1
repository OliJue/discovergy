# Prerequisite:
# OAuth1:
#    https://www.powershellgallery.com/packages/PSAuth/
#    https://github.com/PlagueHO/PSAuth
#    install-module PSAuth -scope currentuser
#      => Get-PSAuthorizationString: Create an OAuth 1.0 Authorization string for use in an HTTP request.
#      => Invoke-PSAuthRestMethod: Execute Invoke-RestMethod including an OAuth 1.0 authorization header.

# user editable variables
$discovergyuser = 'your@email.com'
$discovergypass = 'YourP@ssW0rd'
$start = "01/02/2021 00:00:00"
$end = "28/02/2021 23:00:00"
$filename = '.\discovergy-2021-02.csv'


$DiscovergyUri = "https://api.discovergy.com/public/v1"


# OAuth1 Step 1
function Get-DiscovergyOauth1ConsumerToken {

	param (
		$endpointUri
	)

	Write-Verbose "OAuth1 Step 1: Get Consumer Token..."

	$consumertoken = @{}

	$RestParams = @{
		"URI" = "$endpointUri/oauth1/consumer_token"
		"Method" = 'POST'
		"Headers" = @{
			"accept" = "application/json"
			"Content-Type" = "application/x-www-form-urlencoded"
		}
	}
	$RestBody = @{
		"client" = "MyPowershellScript"
	}
	$return = Invoke-RestMethod @RestParams -Body $RestBody
	
	$consumertoken.Key = $return.key
	$consumertoken.Secret = $return.secret

	Write-Verbose "Output OAuth Consumer Key: $($consumertoken.Key)"
	Write-Verbose "Output OAuth Consumer Secret: $($consumertoken.Secret)"

	return $consumertoken
}

# OAuth1 Step 2
function Get-DiscovergyOauth1RequestToken {

	param (
		$endpointUri,
		$consumerkey,
		$consumersecret
	)

	Write-Verbose "OAuth1 Step 2: Get Request Token..."
	
	#$requesttoken = "" | Select-Object -Property Key,Secret
	$requesttoken = @{}

	Write-Verbose "Input Uri: $endpointUri"
	Write-Verbose "Input Consumer Key: $consumerkey"
	Write-Verbose "Input Consumer Secret: $consumersecret"

	$Method = 'POST'
	$Uri = "$endpointUri/oauth1/request_token"
	$consumersecretsecure = ConvertTo-SecureString $consumersecret -AsPlainText -Force

	$return = Invoke-PSAuthRestMethod -uri $Uri -OauthConsumerKey $consumerkey -OauthConsumerSecret $consumersecretsecure -OauthSignatureMethod HMAC-SHA1 -Method $Method
	
	#$return
	
	$token = $return.split("&")
	
	#$token
	
	$oauthtoken=$token[0].Split("=")[1]
	$oauthtokensecret=$token[1].Split("=")[1]
	
	$requesttoken.Key = $oauthtoken
	$requesttoken.Secret = $oauthtokensecret

	Write-Verbose "Output OAuth Token Key: $($requesttoken.Key)"
	Write-Verbose "Output OAuth Token Secret: $($requesttoken.Secret)"

	return $requesttoken
}

# OAuth1 Step 3
function Get-DiscovergyOauth1Authorization {

	param (
		$endpointUri,
		$oauthtokenkey,
		$email,
		$pass
	)

	Write-Verbose "OAuth1 Step 3: Get Authorization..."

	Write-Verbose "Input Uri: $endpointUri"
	Write-Verbose "Input OAuth Token Key: $oauthtokenkey"
	Write-Verbose "Input User: $email"
	Write-Verbose "Input Pass: $pass"

	$Method = 'GET'
	$emailescaped = [uri]::EscapeDataString($email)
	$passescaped = [uri]::EscapeDataString($pass)
	$Uri = "$endpointUri/oauth1/authorize?oauth_token=$oauthtokenkey&email=$emailescaped&password=$passescaped"
	$RestParams = @{
		"URI" = "$Uri"
		"Method" = $Method
		"Headers" = @{
			"accept" = "application/x-www-form-urlencoded"
		}
	}
	$return = Invoke-RestMethod @RestParams
	
	$oauthverifier = $return.Split("=")[1]
	
	Write-Verbose "Output OAuth Verifier: $oauthverifier"
	
	return $oauthverifier
}

# OAuth1 Step 4
function Get-DiscovergyOauth1AccessToken {

	param (
		$endpointUri,
		$consumerkey,
		$consumersecret,
		$oauthtokenkey,
		$oauthtokensecret,
		$oauthverifier
	)

	Write-Verbose "OAuth1 Step 4: Get Access Token..."

	Write-Verbose "Input Uri: $endpointUri"
	Write-Verbose "Input Consumer Key: $consumerkey"
	Write-Verbose "Input Consumer Secret: $consumersecret"
	Write-Verbose "Input OAuth Token Key: $oauthtokenkey"
	Write-Verbose "Input OAuth Token Secret: $oauthtokensecret"
	Write-Verbose "Input OAuth Verifier: $oauthverifier"


	$accesstoken = @{}


	$Method = 'POST'
	$Uri = "$endpointUri/oauth1/access_token"
	$ExtraParams = @{
		"oauth_verifier" = "$oauthverifier"
	}
	$helper = Get-PSAuthorizationString -Uri $Uri -Method $Method `
		-OauthConsumerKey $consumerkey `
		-OauthConsumerSecret (ConvertTo-SecureString $consumersecret -AsPlainText -Force ) `
		-OauthAccessToken $oauthtokenkey `
		-OauthAccessTokenSecret (ConvertTo-SecureString $oauthtokensecret -AsPlainText -Force ) `
		-OauthParameters $ExtraParams `
		-OauthSignatureMethod HMAC-SHA1
	# OAuth Verifier will be included in Signature by using above OauthParameters, but
	# unfortunately missed in output string. Therefore it will be added here as well.
	$helper += ",oauth_verifier=""$oauthverifier"""
	
	#$helper
	
	$RestParams = @{
		"URI" = "$Uri"
		"Method" = $Method
		"Headers" = @{
			"accept" = "application/x-www-form-urlencoded"
			"Authorization" = "$helper"
		}
	}
	$return = Invoke-RestMethod @RestParams
	
	$accesstoken.Key = $return.Split("&")[0].Split("=")[1]
	$accesstoken.Secret = $return.Split("&")[1].Split("=")[1]
	
	Write-Verbose "Output OAuth Access Token Key: $($accesstoken.Key)"
	Write-Verbose "Output OAuth Access Token Secret: $($accesstoken.Secret)"

	return $accesstoken
}

function Get-DiscovergyMeters {

	param (
		$endpointUri,
		$consumerkey,
		$consumersecret,
		$accesskey,
		$accesssecret
	)

	Write-Verbose "Get available meters..."

	Write-Verbose "Input Uri: $endpointUri"
	Write-Verbose "Input Consumer Key: $consumerkey"
	Write-Verbose "Input Consumer Secret: $consumersecret"
	Write-Verbose "Input OAuth Token Key: $accesskey"
	Write-Verbose "Input OAuth Token Secret: $accesssecret"


	$Method = 'GET'
	$Uri = "$endpointUri/meters"

	$RestParams = @{
		"URI" = "$Uri"
		"Method" = $Method
		"Headers" = @{
			"accept" = "application/json"
		}
	}
	$return = Invoke-PSAuthRestMethod @RestParams `
		-OauthConsumerKey $consumerkey `
		-OauthConsumerSecret (ConvertTo-SecureString $consumersecret -AsPlainText -Force ) `
		-OauthSignatureMethod HMAC-SHA1 `
		-OauthAccessToken $accesskey `
		-OauthAccessTokenSecret (ConvertTo-SecureString $accesssecret -AsPlainText -Force ) 


	#$meters
	$mymeter = $return.meterId

	Write-Verbose "Output Meter ID: $mymeter"

	return $mymeter
}


function Get-DiscovergyFieldNames {

	param (
		$endpointUri,
		$consumerkey,
		$consumersecret,
		$accesskey,
		$accesssecret,
		$meterid
	)

	Write-Verbose "Get field names..."

	Write-Verbose "Input Uri: $endpointUri"
	Write-Verbose "Input Consumer Key: $consumerkey"
	Write-Verbose "Input Consumer Secret: $consumersecret"
	Write-Verbose "Input OAuth Token Key: $accesskey"
	Write-Verbose "Input OAuth Token Secret: $accesssecret"
	Write-Verbose "Meter ID: $meterid"

	$Method = 'GET'
	$Uri = "$endpointUri/field_names?meterId=$meterid"

	$RestParams = @{
		"URI" = "$Uri"
		"Method" = $Method
		"Headers" = @{
			"accept" = "application/json"
		}
	}
	$return = Invoke-PSAuthRestMethod @RestParams `
		-OauthConsumerKey $consumerkey `
		-OauthConsumerSecret (ConvertTo-SecureString $consumersecret -AsPlainText -Force ) `
		-OauthSignatureMethod HMAC-SHA1 `
		-OauthAccessToken $accesskey `
		-OauthAccessTokenSecret (ConvertTo-SecureString $accesssecret -AsPlainText -Force ) 

	$fieldnames = $return

	Write-Verbose ( $fieldnames | Out-String)
	# Values seems to be in milli (milliwatt, millivolt, ...)
	#energy
	#energy1
	#energy2
	#energyOut
	#energyOut1
	#energyOut2
	#power
	#power1
	#power2
	#power3
	#voltage1
	#voltage2
	#voltage3

	return $fieldnames
}

function Get-DiscovergyHourlyPowerData {

	param (
		$endpointUri,
		$consumerkey,
		$consumersecret,
		$accesskey,
		$accesssecret,
		$meterid,
		$starttimestr,
		$endtimestr
	)

	Write-Verbose "Get hourly power data..."

	Write-Verbose "Input Uri: $endpointUri"
	Write-Verbose "Input Consumer Key: $consumerkey"
	Write-Verbose "Input Consumer Secret: $consumersecret"
	Write-Verbose "Input OAuth Token Key: $accesskey"
	Write-Verbose "Input OAuth Token Secret: $accesssecret"
	Write-Verbose "Meter ID: $meterid"
	Write-Verbose "Start date/time: $starttimestr"
	Write-Verbose "End date/time: $endtimestr"

	$Method = 'GET'
	# In opposite to Awattar the API time values fit to GMT+1 time zone. No correction required.
	# Begin time of interval to return readings for, as a UNIX millisecond timestamp
	$unixstart = get-date -date "01/01/1970"
	$start = [int64] (New-TimeSpan -Start $unixstart -End (Get-Date $starttimestr)).TotalMilliseconds
	$end = [int64] (New-TimeSpan -Start $unixstart -End (Get-Date $endtimestr)).TotalMilliseconds
	$resolution = 'one_hour'
	# Power = Milliwatt
	$field = 'power'

	# resolution	maximum time span (to - from)
	# raw				1 day
	# three_minutes		10 days
	# fifteen_minutes	31 days
	# one_hour			93 days
	# one_day			10 years
	# one_week			20 years
	# one_month			50 years
	# one_year			100 years
	$maxrange = 93
	$range = (New-TimeSpan -Start (Get-Date $starttimestr) -End (Get-Date $endtimestr)).TotalDays
	$range = [math]::ceiling($range)
	Write-Verbose "Selected time range is $range days. API limit is $maxrange days for a single request."
	if ($range -gt $maxrange) {
		Write-Error "Selected time range is $range days. Tbhis is above API limit of $maxrange days for a single request."
	}

	$Uri = "$endpointUri/readings?meterId=$meterid&fields=$field&from=$start&to=$end&resolution=$resolution&disaggregation=false&each=false"

	$RestParams = @{
		"URI" = "$Uri"
		"Method" = $Method
		"Headers" = @{
			"accept" = "application/json"
		}
	}
	$return = Invoke-PSAuthRestMethod @RestParams `
		-OauthConsumerKey $consumerkey `
		-OauthConsumerSecret (ConvertTo-SecureString $consumersecret -AsPlainText -Force ) `
		-OauthSignatureMethod HMAC-SHA1 `
		-OauthAccessToken $accesskey `
		-OauthAccessTokenSecret (ConvertTo-SecureString $accesssecret -AsPlainText -Force ) 


	# Convert human readable
	# Date/Time from unix to string
	# Power from Milliwatt to Watt
	$data = @()

	foreach ($entry in $return) {
		$datetime = $unixstart.AddMilliseconds($entry.time)
		$datetimestr = ("{0}" -f $datetime)
		$value = $entry.values.$field / 1000
		$data += [PSCustomObject]@{
			'Measure_Range_1h' = $datetimestr
			'Power_used_Wh' = $value
		}
	}

	return $data
}



#
# Main
#

$VerbosePreference = "Continue"
$ErrorActionPreference = "Stop"

$consumertoken = Get-DiscovergyOauth1ConsumerToken $DiscovergyUri
$requesttoken = Get-DiscovergyOauth1RequestToken $DiscovergyUri $consumertoken.key $consumertoken.secret
$oauthverifier = Get-DiscovergyOauth1Authorization $DiscovergyUri $requesttoken.key $discovergyuser $discovergypass
$accesstoken = Get-DiscovergyOauth1AccessToken $DiscovergyUri `
		$consumertoken.key $consumertoken.secret $requesttoken.key $requesttoken.secret $oauthverifier

$meterid = Get-DiscovergyMeters $DiscovergyUri $consumertoken.key $consumertoken.secret $accesstoken.key $accesstoken.secret

#$fieldnames = Get-DiscovergyFieldNames $DiscovergyUri $consumertoken.key $consumertoken.secret $accesstoken.key $accesstoken.secret $meterid

$powerdata = Get-DiscovergyHourlyPowerData $DiscovergyUri $consumertoken.key $consumertoken.secret $accesstoken.key $accesstoken.secret $meterid $start $end

$powerdata | export-csv -path $filename

