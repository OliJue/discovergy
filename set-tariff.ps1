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

	#Write-Verbose ($return | Out-String )
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

function Set-DiscovergyTariff {

	param (
		$endpointUri,
		$consumerkey,
		$consumersecret,
		$accesskey,
		$accesssecret,
		$meterid,
		$providerName,
		$tariffName,
		$monthlyBasePrice,
		$pricePerKwh,
		$monthlyInstallment,
		$user
	)

	Write-Verbose "Set Tariff..."

	Write-Verbose "Input Uri: $endpointUri"
	Write-Verbose "Input Consumer Key: $consumerkey"
	Write-Verbose "Input Consumer Secret: $consumersecret"
	Write-Verbose "Input OAuth Token Key: $accesskey"
	Write-Verbose "Input OAuth Token Secret: $accesssecret"
	Write-Verbose "Input Meter ID: $meterid"

	Write-Verbose "Input Provider Name: $providerName"
	Write-Verbose "Input Tariff Name: $tariffName"
	Write-Verbose "Input Monthly Base Price: $monthlyBasePrice"
	Write-Verbose "Input Price per kWh: $pricePerKwh"
	Write-Verbose "Input Monthly Installment: $monthlyInstallment"
	Write-Verbose "Input User E-Mail: $user"

	$Method = 'POST'
	$Uri = "$endpointUri/tariff"

	$RestParams = @{
		"URI" = "$Uri"
		"Method" = $Method
		"Headers" = @{
			"accept" = "application/json"
			#"accept" = "text/plain"
			#"accept" = "*/*"
			#"Content-Type" = "application/x-www-form-urlencoded"
			#"Content-Type" = "multipart/form-data"
			"Content-Type" = "application/json"
		}
	}

	$RestBody = @{
		"meterId" = $meterid
		"tariff" = @{
			"providerName" = $providerName
			"tariffName" = $tariffName
			"monthlyBasePrice" = $monthlyBasePrice
			"pricePerKwh" = $pricePerKwh
			"monthlyInstallment" = $monthlyInstallment
		}
		"user" = $user
	}
	
	Write-Verbose ( $RestBody | ConvertTo-Json | Out-String )
	#Write-Verbose ( ($RestBody.tariff) | Out-String )

	$response = Invoke-PSAuthRestMethod @RestParams -Body ($RestBody | ConvertTo-Json) -ContentType "application/json" `
		-OauthConsumerKey $consumerkey `
		-OauthConsumerSecret (ConvertTo-SecureString $consumersecret -AsPlainText -Force ) `
		-OauthSignatureMethod HMAC-SHA1 `
		-OauthAccessToken $accesskey `
		-OauthAccessTokenSecret (ConvertTo-SecureString $accesssecret -AsPlainText -Force ) 

	Write-Verbose ( $response | Out-String)
	
	return $response
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

#$result = Set-DiscovergyTariff $DiscovergyUri $consumertoken.key $consumertoken.secret $accesstoken.key $accesstoken.secret `
#		$meterid "eprimo" "eprimo.klar" "14.02" "26.93" "0" $discovergyuser
		# providerName tariffName monthlyBasePrice pricePerKwh monthlyInstallment email

$result = Set-DiscovergyTariff $DiscovergyUri $consumertoken.key $consumertoken.secret $accesstoken.key $accesstoken.secret `
		$meterid "eprimo" "eprimo" "14" "26" "0" $discovergyuser
		# providerName tariffName monthlyBasePrice pricePerKwh monthlyInstallment email
