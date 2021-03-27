$yearmonth = '2021-01'
$consumption = Import-Csv .\discovergy-$yearmonth.csv
$marketdata = Import-Csv .\awattar-upd-$yearmonth.csv
$consumptionheaderrange = 'Zeitbereich'
$consumptionheaderusage = 'Verbrauch Wh'
$marketdataheaderrange = 'Range_1h'
$marketdataheaderprice = 'Total_Cost_ct_each_kWh'

$VerbosePreference = "Continue"
$ErrorActionPreference = "Stop"

$exdata = @()

for ( $i=0; $i -lt $consumption.count ; $i++) {
	#write-host $i
	if($consumption[$i].$consumptionheaderrange -ne $marketdata[$i].$marketdataheaderrange){
		Write-Error "Must be equal: Consumption={0} Marketdata={1}" -f $consumption[$i].$consumptionheaderrange,$marketdata[$i].$marketdataheaderrange
	} else {
		$powr = [decimal] ($consumption[$i].$consumptionheaderusage).Replace(",",".")
		$price = [decimal] ($marketdata[$i].$marketdataheaderprice).Replace(",",".")
		# Convert from
		# ct -> EUR (/100)
		# Wh -> kWh (/1000)
		$endprice = $powr * $price / 100 / 1000
		#write-host "$powr  - $price  - $endprice"
		Write-Verbose "Range: $($consumption[$i].$consumptionheaderrange)  Power: $powr  Price: $price  Endprice: $endprice"
		$exdata += [PSCustomObject]@{
			'Range_1h' = $consumption[$i].$consumptionheaderrange
			'Cost_EUR' = $endprice
		}
	}
}

#$exdata

$exdata | export-csv -path ".\merge-$yearmonth.csv"
