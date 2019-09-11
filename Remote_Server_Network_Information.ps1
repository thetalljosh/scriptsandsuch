﻿<#
			" Satnaam WaheGuru Ji"	
			
			Author  :  Aman Dhally
			E-Mail  :  amandhally@gmail.com
			website :  www.amandhally.net
			twitter : https://twitter.com/#!/AmanDhally
			facebook: http://www.facebook.com/groups/254997707860848/
			Linkedin: http://www.linkedin.com/profile/view?id=23651495

			Date	: 18-Sept-2012
			File	: Office_2010_Trusted_Locations
			Purpose : Getting Network Information of Multile Servers
			
			Version : 1

			my Spider runned Away :( 


#>


	param (
	[array]$arrComputer="$env:computername"
	)
	
	"`n"
	
	Write-Host "Name|    NetworkCard                                  | IP          | SUBNET      | GateWay      | MacADD           | DNS "  -ForegroundColor Green 

foreach ( $Computer in $arrComputer ) { 
	

	$nwINFO = Get-WmiObject -ComputerName $Computer Win32_NetworkAdapterConfiguration | Where-Object { $_.IPAddress -ne $null } #| Select-Object DNSHostName,Description,IPAddress,IpSubnet,DefaultIPGateway,MACAddress,DNSServerSearchOrder | format-Table * -AutoSize 
	#| Select-Object DNSHostName,Description,IPAddress,IpSubnet,DefaultIPGateway,MACAddress,DNSServerSearchOrder
	$nwServerName = $nwINFO.DNSHostName
	$nwDescrip = $nwINFO.Description
	$nwIPADDR = $nwINFO.IPAddress
	$nwSUBNET = $nwINFO.IpSubnet
	$nwGateWay = $nwINFO.DefaultIPGateway
	$nwMacADD = $nwINFO.MACAddress
	$nwDNS = $nwINFO.DNSServerSearchOrder
	#		Server/CompName   |NetworkCard | IPAdress  |  SubnetMask|  Gateway	| MAC Address|   DNS |
	Write-Host "$nwServerName | $nwDescrip | $nwIPADDR | $nwSUBNET | $nwGateWay | $nwMacADD | $nwDNS " | ft *

	}

