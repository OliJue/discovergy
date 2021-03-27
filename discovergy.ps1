$endpointUri="https://api.discovergy.com/public/v1"

# Oauth1

# Prerequisite:
# OAuth1:
#    https://www.powershellgallery.com/packages/PSAuth/
#    https://github.com/PlagueHO/PSAuth
#    install-module PSAuth -scope currentuser
#      => Get-PSAuthorizationString: Create an OAuth 1.0 Authorization string for use in an HTTP request.
#      => Invoke-PSAuthRestMethod: Execute Invoke-RestMethod including an OAuth 1.0 authorization header.

$discovergyuser = 'your@email.com'
$discovergypass = 'yourP@ssw0rd'


write-host "Get Consumer Token..." -ForeGroundColor GREEN

$Params = @{
	"URI" = "$endpointUri/oauth1/consumer_token"
	"Method" = 'POST'
	"Headers" = @{
		"accept" = "application/json"
		"Content-Type" = "application/x-www-form-urlencoded"
	}
}
$Body = @{
	"client" = "MyPowershellScript"
}
$consumertoken = Invoke-RestMethod @Params -Body $body

$consumertokenkey = $consumertoken.key
$consumertokensecret = $consumertoken.secret

write-host "oauth_consumer_key=$consumertokenkey"
write-host "oauth_consumer_secret=$consumertokensecret"
#$consumertoken

write-host "Get Request Token..." -ForeGroundColor GREEN

$Method = 'POST'
$Uri = "$endpointUri/oauth1/request_token"
$ConsumerSecret = ConvertTo-SecureString $consumertokensecret -AsPlainText -Force
#$ExtraParams = @{
#	"oauth_callback" = "oob"
#}
#$authstring = Get-PSAuthorizationString -uri $Uri -OauthParameters $ExtraParams -OauthConsumerKey $consumertokenkey -OauthConsumerSecret $ConsumerSecret -OauthSignatureMethod HMAC-SHA1 -Method $Method
#$authstring += ',oauth_callback="oob"'
#$authstringescape = [System.Uri]::EscapeDataString($authstring)
#$authstringescape = ConvertTo-PSUrl
#$Params = @{
#	"URI" = "$Uri"
#	"Method" = $Method
#	"Headers" = @{
#		"accept" = "text/plain"
#		"Authorization" = "$authstring"
#	}
#}
$requesttoken = Invoke-PSAuthRestMethod -uri $Uri -OauthConsumerKey $consumertokenkey -OauthConsumerSecret $ConsumerSecret -OauthSignatureMethod HMAC-SHA1 -Method $Method

#$requesttoken

$token = $requesttoken.split("&")

#$token

$oauthtoken=$token[0].Split("=")[1]
$oauthtokensecret=$token[1].Split("=")[1]

write-host "oauth_token=$oauthtoken"
write-host "oauth_token_secret=$oauthtokensecret"

write-host "Authorize..." -ForeGroundColor GREEN
$Method = 'GET'
$email = [uri]::EscapeDataString($discovergyuser)
$pass = [uri]::EscapeDataString($discovergypass)
$Uri = "$endpointUri/oauth1/authorize?oauth_token=$oauthtoken&email=$email&password=$pass"
$Params = @{
	"URI" = "$Uri"
	"Method" = $Method
	"Headers" = @{
		"accept" = "application/x-www-form-urlencoded"
	}
}
$oauth_verifier = Invoke-RestMethod @Params

$oauth_verifier = $oauth_verifier.Split("=")[1]

write-host "oauth_verifier=$oauth_verifier"

write-host "Access Token..." -ForeGroundColor GREEN
$Method = 'POST'
$Uri = "$endpointUri/oauth1/access_token"
$ExtraParams = @{
	"oauth_verifier" = "$oauth_verifier"
}
$helper = Get-PSAuthorizationString -Uri $Uri -Method $Method `
	-OauthConsumerKey $consumertokenkey `
	-OauthConsumerSecret $ConsumerSecret `
	-OauthAccessToken $oauthtoken `
	-OauthAccessTokenSecret (ConvertTo-SecureString $oauthtokensecret -AsPlainText -Force ) `
	-OauthParameters $ExtraParams `
	-OauthSignatureMethod HMAC-SHA1
$helper += ",oauth_verifier=""$oauth_verifier"""

#$helper

$Params = @{
	"URI" = "$Uri"
	"Method" = $Method
	"Headers" = @{
		"accept" = "application/x-www-form-urlencoded"
		"Authorization" = "$helper"
	}
}
$oauth_final = Invoke-RestMethod @Params

$my_oauth_token = $oauth_final.Split("&")[0].Split("=")[1]
$my_oauth_token_secret = $oauth_final.Split("&")[1].Split("=")[1]

write-host "oauth_token=$my_oauth_token"
write-host "oauth_token_secret=$my_oauth_token_secret"

##########

write-host "Get available meters..." -ForeGroundColor GREEN
$Method = 'GET'
$Uri = "$endpointUri/meters"

$Params = @{
	"URI" = "$Uri"
	"Method" = $Method
	"Headers" = @{
		"accept" = "application/json"
	}
}
$meters = Invoke-PSAuthRestMethod @Params `
	-OauthConsumerKey $consumertokenkey `
	-OauthConsumerSecret $ConsumerSecret `
	-OauthSignatureMethod HMAC-SHA1 `
	-OauthAccessToken $my_oauth_token `
	-OauthAccessTokenSecret (ConvertTo-SecureString $my_oauth_token_secret -AsPlainText -Force ) 


#$meters
$mymeter = $meters.meterId

write-host "Meter ID: $mymeter"


write-host "Get field names..." -ForeGroundColor GREEN
$Method = 'GET'
$Uri = "$endpointUri/field_names?meterId=$mymeter"

$Params = @{
	"URI" = "$Uri"
	"Method" = $Method
	"Headers" = @{
		"accept" = "application/json"
	}
}
$fieldnames = Invoke-PSAuthRestMethod @Params `
	-OauthConsumerKey $consumertokenkey `
	-OauthConsumerSecret $ConsumerSecret `
	-OauthSignatureMethod HMAC-SHA1 `
	-OauthAccessToken $my_oauth_token `
	-OauthAccessTokenSecret (ConvertTo-SecureString $my_oauth_token_secret -AsPlainText -Force ) 

$fieldnames
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



write-host "Get first data..." -ForeGroundColor GREEN
$Method = 'GET'
# in opposite to Awattar the API time values fit to GMT+1 time zone. No correction required.
# Begin time of interval to return readings for, as a UNIX millisecond timestamp
$unixstart = get-date -date "01/01/1970"
$start = [int64] (New-TimeSpan -Start $unixstart -End (Get-Date "01/02/2021 00:00:00")).TotalMilliseconds
$ende = [int64] (New-TimeSpan -Start $unixstart -End (Get-Date "28/02/2021 23:00:00")).TotalMilliseconds
$resolution = 'one_hour'
$field = 'power'
# Power = Milliwatt
# 
# resolution	maximum time span (to - from)
# raw				1 day
# three_minutes		10 days
# fifteen_minutes	31 days
# one_hour			93 days
# one_day			10 years
# one_week			20 years
# one_month			50 years
# one_year			100 years
$Uri = "$endpointUri/readings?meterId=$mymeter&fields=$field&from=$start&to=$ende&resolution=$resolution&disaggregation=false&each=false"

$Params = @{
	"URI" = "$Uri"
	"Method" = $Method
	"Headers" = @{
		"accept" = "application/json"
	}
}
$data = Invoke-PSAuthRestMethod @Params `
	-OauthConsumerKey $consumertokenkey `
	-OauthConsumerSecret $ConsumerSecret `
	-OauthSignatureMethod HMAC-SHA1 `
	-OauthAccessToken $my_oauth_token `
	-OauthAccessTokenSecret (ConvertTo-SecureString $my_oauth_token_secret -AsPlainText -Force ) 

#$data

$summary = 0

foreach ($entry in $data) {
	$zeit = $unixstart.AddMilliseconds($entry.time)
	$value = $entry.values.$field / 1000
	$summary += $value
	write-host ("Zeitbereich {0}: {1} {2:n1}" -f $zeit,$field,$value)
}

write-host ("Sum {0} {1:n0}" -f $field, $summary) -ForeGroundColor GREEN
write-host "Note: power = Wh"

write-host "Export data..." -ForeGroundColor GREEN

$exdata = @()

foreach ($entry in $data) {
	$zeit = $unixstart.AddMilliseconds($entry.time)
	$zeitstr = ("{0}" -f $zeit)
	$value = $entry.values.$field / 1000
	$exdata += [PSCustomObject]@{
		'Zeitbereich' = $zeitstr
		'Verbrauch Wh' = $value
	}
}

$exdata

$exdata | export-csv -path '.\discovergy-data.csv'

