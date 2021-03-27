
# Awattar Fair use policy = 60 requests / minute
# currently no token required
# return values excluding tax
#
# Important: seems to run on UTC
$unixstart = (get-date -date "01/01/1970").AddHours(1)
$start = [int64] (New-TimeSpan -Start $unixstart -End (Get-Date "01/02/2021 00:00:00")).TotalMilliseconds
$ende = [int64] (New-TimeSpan -Start $unixstart -End (Get-Date "01/03/2021 00:00:00")).TotalMilliseconds

write-host "Get Costs..." -ForeGroundColor GREEN

$Params = @{
	"URI" = "https://api.awattar.de/v1/marketdata?start=$start&end=$ende"
	"Method" = 'GET'
}
$response = Invoke-WebRequest @Params
#$response

$costs = ($response.Content | convertfrom-json ).data
#$costs

foreach ($entry in $costs) {
	$zeit = $unixstart.AddMilliseconds($entry.start_timestamp)
	$zeit2 = $unixstart.AddMilliseconds($entry.end_timestamp)
	# Note: Default §entry.unit = Eur/MWh
	#       converted to ct/kWh
	$price = $entry.marketprice / 1000 * 100
	# add Netznutzung Umlagen Abgaben Stuern Spotaufpreis tax (19%)
	$endprice = 20.33 + (($price + 0.25) * 1.19)
	write-host ("Zeitbereich {0} - {1}: {2:n2}  Gesamtpreis: {3:n2}" -f $zeit,$zeit2,$price,$endprice)
}

write-host "Export data..." -ForeGroundColor GREEN

$exdata = @()

foreach ($entry in $costs) {
	$zeit = $unixstart.AddMilliseconds($entry.start_timestamp)
	$zeitstr = ("{0}" -f $zeit)
	# EUR/MWh -> ct/kWh
	$price = $entry.marketprice / 1000 * 100
	# add Netznutzung Umlagen Abgaben Stuern Spotaufpreis tax (19%)
	$endprice = 20.33 + (($price + 0.25) * 1.19)
	$exdata += [PSCustomObject]@{
		'Zeitbereich' = $zeitstr
		'Preis ct/kWh' = $endprice
	}
}

$exdata

$exdata | export-csv -path '.\awattar-data.csv'

