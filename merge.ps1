$verbrauch = import-csv .\discovergy-2021-02.csv
$kosten = Import-Csv .\awattar-2021-02.csv

$exdata = @()

for ( $i=0; $i -lt $verbrauch.count ; $i++) {
	#write-host $i
	if($verbrauch[$i].zeitbereich -ne $kosten[$i].zeitbereich){
		write-host "Ungleich: Verbrauch={0} Kosten={1}" -f verbrauch[$i].zeitbereich,$kosten[$i].zeitbereich
		exit
	} else {
		$powr = [decimal] ($verbrauch[$i].'Verbrauch Wh').Replace(",",".")
		$price = [decimal] ($kosten[$i].'Preis ct/kWh').Replace(",",".")
		# ct -> EUR (/100)
		# Wh -> kWh (/1000)
		$endprice = $powr * $price / 100 / 1000
		#write-host "$powr  - $price  - $endprice"
		$exdata += [PSCustomObject]@{
			'Zeitbereich' = $verbrauch[$i].zeitbereich
			'Kosten EUR' = $endprice
		}
	}
}

$exdata

$exdata | export-csv -path '.\merge-data.csv'