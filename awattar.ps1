
# Awattar Fair use policy = 60 requests / minute
# currently no token required
# return values excluding tax
#
# Important: Awattar seems to run on UTC. Requires time offset.

# user editable variables
$start = "01/12/2020 00:00:00"
$end = "01/01/2021 00:00:00"
$filename = '.\awattar-upd-2020-12.csv'
#$start = "27/03/2021 00:00:00"
#$end = "28/03/2021 00:00:00"
#$filename = '.\awattar-2021-03-27.csv'


$AwattarUri = "https://api.awattar.de/v1"

function Get-AwattarMarketdata {

	param (
		$endpointUri,
		$starttimestr,
		$endtimestr
	)

	Write-Verbose "Get hourly power cost..."

	Write-Verbose "Input Uri: $endpointUri"
	Write-Verbose "Input Start date/time: $starttimestr"
	Write-Verbose "Input End date/time: $endtimestr"
	
	# add one hour winter time Germany
	$unixstart = (get-date -date "01/01/1970").AddHours(1)
	$startms = [int64] (New-TimeSpan -Start $unixstart -End (Get-Date $starttimestr)).TotalMilliseconds
	$endms = [int64] (New-TimeSpan -Start $unixstart -End (Get-Date $endtimestr)).TotalMilliseconds
	
	$WebParams = @{
		"URI" = "$endpointUri/marketdata?start=$startms&end=$endms"
		"Method" = 'GET'
	}
	$response = Invoke-WebRequest @WebParams
	
	$costs = ($response.Content | convertfrom-json ).data

	$data = @()
	
	foreach ($entry in $costs) {
		Write-Verbose "  $entry"
		$datetime = $unixstart.AddMilliseconds($entry.start_timestamp)
		$datetimestr = ("{0}" -f $datetime)
		# convert EUR/MWh to ct/kWh
		# Marketprice return values excl. tax (compared with https://www.awattar.de/tariffs/hourly)
		$price = $entry.marketprice / 1000 * 100
		# add Netznutzung Umlagen Abgaben Stuern Spotaufpreis tax (19%)
		# the 0.250 cent/kWh already includes tax (mentioned https://www.awattar.de/tariffs/hourly)
		$endprice = 20.33 + 0.25 + ($price * 1.19)
		$data += [PSCustomObject]@{
			'Range_1h' = $datetimestr
			'marketprice_raw' = $entry.marketprice
			'Total_Cost_ct_each_kWh' = $endprice
		}
	}

	return $data
}


#
# Main
#

$VerbosePreference = "Continue"
$ErrorActionPreference = "Stop"


$costdata = Get-AwattarMarketdata $AwattarUri $start $end

$costdata | export-csv -path $filename

