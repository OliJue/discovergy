# Discovergy API / Awattar API

## Overview

I own a smart meter from Discovergy.com. I wonder if it might be useful to change from a Electricity supplier with a fixed price per kWh to some of the new ones like Awattar or Tibber. Both offer a hourly price.
My question was how can I leverage my perosnal history of power consumption (with a real hourly based profile) to match it with a hourly tariff.

Even if the Discovergy API is somehow documented, it took me some hours to successfully do the OAuth 1.0 stuff.

As of now the provided code has any error handling, everthing is hard coded. I am going to improve this stuff over the next days.

## Usage

Install PSAuth

Modify user editable variables within script

Start .\generate_report.ps1


## Known Issues

No error handling
No workaround for Discovergy API limit of max. 91 days for a single request
User input needs modification of the script(s)

## Environment

PSAuth 0.1.4.80
Powershell 5.1.19041.868
