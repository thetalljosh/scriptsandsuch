<#
Synopsis
Generates a list of computer information

DESCRIPTION
This function generates a list by querying the WMI provider and returning the various details of the local or remote computer.

NOTES   
Author: Jaap Brasser
DateCreated: 23/08/2013

Blog: http://www.jaapbrasser.com

Description:
Will generate a list of various components or programs on local machine

HISTORY
23/08/2013 Version 1.0 - Jaap Brasser: Created
28/02/2015 Version 2.0 - Jaap Brasser: Modified
01/03/2015 Version 2.1 - Adrian Jackson: replaced the default output fields if "property" parameter is given rather than always display the default fields.
09/04/2015 Version 2.2 - Arran Collier: General updated to the layout of the script in order to preserve best practises
10/04/2015 Version 2.3 - Arran Collier: Added date to general information
14/04/2015 Version 2.4 - Arran Collier: Added logging information. Also added the ability to overwrite the default directory by passing in a argument when calling the script.
           Version 2.5 - Arran Collier: Added functionality for single machine. If there is no computer list found use the local machine.
           Version 2.6 - Arran Collier: Added functionality to collect the services information and export this as a CSV.
           Version 2.7 - Arran collier: Corrected some formatting errors + spelling mistakes.
           Version 2.8 - Arran Collier: Added functionality to collect MAC Addresses and export to a CSV folder.
           Version 2.9 - Arran Collier: Updated services function to use the win32_baseservice provider instead, as more information can be collected.
           Version 3.0 - Arran Collier: Updated OS file to correct the seriel number output
           Version 3.1 - Arran Collier: Updated the Serial number collection to try and identify why some serial numbers are not being collected.
27/05/2015 Version 3.2 - Arran Collier: Added "installsource" when querying the registry as this can contain install location as well.
08/06/2015 Version 4.0 - Arran Collier: Added the ability to deal with Alias'
22/06/2015 Version 4.1 - Arran Collier: Changed the script to append the information after it is collected for each computer. To prevent any loss of information if the script errors.
19/08/2015 Version 4.2 - Arran Collier: Changed serial number collection, to try and elimnate errors
01/09/2015 Version 4.3 - Arran Collier: Replaced .Trim(" ") with .trim() - to see if this resolves legacy issues.
01/09/2015 Version 4.4 - Arran Collier: Removed issues surrounding Serial number collection.
01/09/2015 Version 4.5 - Arran Collier: Handled serial number Arrays and strings, as this varies depending on powershell version.
03/09/2015 Version 4.7 Legacy - Arran Collier: Legacy support. Reverted back to version 4.1 in terms of exporting the csv files, but kept all other functionality of version 4.5
#>

function wLog($strText) 
{
    #update todays date
    $td = get-date -format "yyyyMMdd-HH.mm.ss"
    "$td - $strText" | Out-File $logfile -Append
} 

Function Inventory-Main 
{    
    $td = get-date -format "yyyyMMdd-HH.mm.ss"
    $tdf = get-date -format "yyyy-MM-dd HH:mm:ss"    
    $GeneralInfo = @()
    $OSInfo = @()
    $ServicesList = @()
    $MACAddressList = @()
    $ProcessorInfo = @()
    $Uninstall_List = @()
    $SoftWareInfo = @()
    $SerialNumber = @()

    wLog "Info:  Iterating through the list of computers one by one."
    ForEach ($ComputerName in $ComputerList)
    {         
        
        wLog "Info: Checking to see if this is being run locally or from hostnames.CSV, this will be important to see if Alias' have been input"
        if (($ComputerList.$hostname.count -gt 1) -or ($alias -ne "LOCAL"))
        {
            wLog "Info: Script is being run from the Hostnames.csv file, therefore we need to check for Alias'"
            wLog "Info: Checking to see is an Alias exists"
            If ($ComputerName.$alias.length -gt 1)
            {
                wLog "Info: Alias is present, so we do not output hostname. This is now replaced with an Alias."
                $alias = $ComputerName.$alias
            }
            else
            {
                wLog "Info: Alias is not present so we can continue to use the hostname"
                $alias = $ComputerName.$hostname
            }

            wLog "Info: Checking to see if a hostname/server name has been provided in order for us to ping it"
            If ($ComputerName.$hostname -ne "")
            { 
                wLog "Info: A hostname has been provided. Making the hostname the default - so we can ping - but this will not be output"
                $computerName = $ComputerName.$hostname
            }
            else
            {
                wLog "Error: We havent been provided with a hostname so we cant ping the server, skipping to next record in the list"
                continue
            }
        }
        else
        {
            wLog "Info: Script is being run locally without a Hostnames.csv file, meaning there can't be an Alias"
            $alias = $ComputerName
        }

        #write-host Gathering info for $ComputerName
        wLog "Info:  Gathering info for $alias"
        
        # Collect SERIALNUMBER information    
        wLog "Info:  About to collect Serial number information for $alias"

        $TempSerialNumber = get-wmiobject -Computer $ComputerName -Class win32_bios  | select -Property SerialNumber

        Try
        {
        #Try and treat this as an object, however if it isnt one, error and default to using it as a string
            if ($TempSerialNumber.SerialNumber.trim() -eq "")
            {
                wLog "Error:  Serial number information was not sucessfully collected for $alias"
            }
            else
            {
                $SerialNumber = $TempSerialNumber.SerialNumber.trim()

                wLog "Info:  Serial number information sucessfully collected for $alias"
                wLog "Info:  Serial number being collected for $alias is $SerialNumber"
            } 
        }
        Catch
        {
            if (($TempSerialNumber.trim()) -eq "")
            {
                wLog "Error:  Serial number information was not sucessfully collected for $alias"
            }
            else
            {
                $SerialNumber = $TempSerialNumber.trim()

                wLog "Info:  Serial number information sucessfully collected for $alias"
                wLog "Info:  Serial number being collected for $alias is $SerialNumber"
            } 
        }           

        
        # Collect PROCESSOR Details
        Try 
        {
            wLog "Info:  About to collect processor information for $alias"
            $Processors = get-wmiobject -Computer $ComputerName -Class win32_Processor | select -Property @{Name="System Name";Expression={$alias}}, @{Name="Serial Number";Expression={$SerialNumber}},
            AddressWidth, Architecture, Availability, CpuStatus, CurrentClockSpeed, DataWidth, Description, DeviceID, ExtClock,
            Family, Level, Manufacturer, MaxClockSpeed, Name, NumberOfCores, NumberOfLogicalProcessors, ProcessorId, ProcessorType,
            Revision, Role, SocketDesignation, Status, StatusInfo, Stepping, UniqueId 
    
            $ProcessorInfo+=$Processors
            
            wLog "Info:  Processor information sucessfully collected for $alias"
        }
        Catch
        {
            wLog "Error:  Processor information was not sucessfully collected for $alias"
            wLog $Error
        }        


        # Collect GENERAL INFORMATION
        Try
        {
            wLog "Info:  About to collect general information for $alias"
            $ComputerSystem = Get-WmiObject -Computer $ComputerName -Class Win32_ComputerSystem | 
                Select -Property @{Name="System Name";Expression={$alias}}, @{Name="Serial Number";Expression={$SerialNumber}}, 
                Model , Manufacturer , Description , PrimaryOwnerName , SystemType,TotalPhysicalMemory, NumberOfLogicalProcessors,NumberOfProcessors, @{Name="Scan Date";Expression={$tdf}}
     
            $GeneralInfo+=$ComputerSystem

            wLog "Info:  Processor information sucessfully collected for $alias"
        }
        Catch
        {
            wLog "Error:  collected information was not sucessfully collected for $alias"
            wLog $Error
        }

        # Collect OPERATING SYSTEM Information
        Try
        {
            wLog "Info:  About to collect OS information for $alias"             
            $OS = Get-WmiObject -Computer $ComputerName -Class Win32_OperatingSystem | 
                Select -Property @{Name="System Name";Expression={$alias}} , @{Name="Serial Number";Expression={$SerialNumber}}, Caption , CSDVersion , 
                OSArchitecture , OSLanguage , BuildNumber , Manufacturer ,  Version , Organization , OSProductSuite , OSType , SerialNumber , SuiteMask
              
            $OSInfo+=$OS

            wLog "Info:  OS information sucessfully collected for $alias"
        }
        Catch
        {
            wLog "Error:  OS information was not sucessfully collected for $alias"
            wLog $Error
        }

        # Collect MAC Address Information
        Try 
        {
            wLog "Info:  About to collect MAC Address information for $alias" 
            $MACAddressInfo = Get-WmiObject -Computer $ComputerName -Class Win32_NetworkAdapterConfiguration| Where{($_.MACAddress.length) -gt 1}  |
            Select -Property @{Name="System Name";Expression={$alias}} , @{Name="Serial Number";Expression={$SerialNumber}}, Description , MACAddress

            $MACAddressList+=$MACAddressInfo

            wLog "Info:  MAC Address information was sucessfully collected for $alias"
        }
        Catch
        {
            wLog "Error:  MAC Address information was not sucessfully collected for $alias"
            wLog $Error
        }

        # Collect SERVICES Information
        Try 
        {
            wLog "Info:  About to collect services information for $alias" 
            $ServicesInfo = Get-WmiObject -Computer $ComputerName -Class win32_baseservice |
            Select -Property @{Name="System Name";Expression={$alias}} , @{Name="Serial Number";Expression={$SerialNumber}}, Name , DisplayName , Caption , Description ,
                installdate , pathname , servicetype , status , startmode 

            $ServicesList+=$ServicesInfo

            wLog "Info:  Service information was sucessfully collected for $alias"
        }
        Catch
        {
            wLog "Error:  Service information was not sucessfully collected for $alias"
            wLog $Error
        }

        # Collect SOFTWARE from the WMI Provider
        Try 
        {
            wLog "Info:  About to collect software information from the WMI provider for $alias" 
            $Software = Get-WmiObject -Computer $ComputerName -Class Win32_Product |
            Select -Property @{Name="System Name";Expression={$alias}} ,@{Name="Serial Number";Expression={$SerialNumber}}, Vendor , Version , Caption 

            $SoftwareInfo+=$Software

            wLog "Info:  Software information from the WMI provider was sucessfully collected for $alias"
        }
        Catch
        {
            wLog "Error:  Software information from the WMI provider was not sucessfully collected for $alias"
            wLog $Error
        }

        # Collect SOFTWARE from Registry
        Try
        {
            wLog "Info:  About to collect Software information from the registry for $alias"  
            $UList =  Get-RemoteProgram -Computer $ComputerName -Property publisher, displayname, displayversion, InstallSource, InstallLocation, language, installdate | 
            select -Property @{Name="System Name";Expression={$alias}},@{Name="Serial Number";Expression={$SerialNumber}}, publisher, displayname, displayversion, InstallLocation, language, installdate

            $Uninstall_List+=$UList

            wLog "Info:  Software information from the registry was sucessfully collected for $alias"
        }
        Catch
        {
            wLog "Error:  Software information from the registry was not sucessfully collected for $alias"
            wLog $Error
        }
    }

    wLog "Info: Exporting information to CSVs"


    #Export PROCESSOR INFORMATION
    Try
    {
        wLog "Info:  Exporting processor information for $alias"
        $ProcessorInfo | Export-Csv -NoType $directory\Processors-$td.csv
        wLog "Info:  Export of Processor information for $alias was successful"
    }
    Catch
    {
        wLog "Error:  Exporting of the processor information was not successful for $alias"
        wLog $Error
    }

    #Export GENERAL INFORMATION
    Try
    {
        wLog "Info:  Exporting general information for $alias" 
        $GeneralInfo | Export-Csv -NoType $directory\General-$td.csv
        wLog "Info:  Export of general information for $alias was successful" 
    }
    Catch
    {
        wLog "Error:  Exporting of the general information was not successful for $alias"
        wLog $Error
    }

    #Export OPERATING SYSTEM Information
    Try
    {
        wLog "Info:  Exporting OS information for $alias"
        $OSInfo  | Export-Csv -NoType $directory\OS-$td.csv
        wLog "Info:  Export of OS information for $alias was successful"
    }
    Catch
    {
        wLog "Error:  Exporting of the OS information was not successful for $alias"
        wLog $Error
    }

    #Export MAC ADDRESS INFORMATION
    Try
    {
        wLog "Info:  Exporting MAC Address information for $alias"
        $MACAddressList  | Export-Csv -NoType $directory\MACAddress-$td.csv
        wLog "Info:  Export of MAC Address information for $alias was successful"
    }
    Catch
    {
        wLog "Error:  Exporting of the MAC Address information was not successful for $alias"
        wLog $Error
    }

    #Export SERVICE INFORMATION
    Try
    {
        wLog "Info:  Exporting service information for $alias"
        $ServicesList  | Export-Csv -NoType $directory\Services-$td.csv
        wLog "Info:  Export of services information for $alias was successful"
    }
    Catch
    {
        wLog "Error:  Exporting of the services information was not successful for $alias"
        wLog $Error
    }

    #Export SOFTWARE INFORMATION from the WMI provider
    Try
    {
        wLog "Info:  Exporting software information from the WMI provider for $alias"
        $SoftWareInfo  | Export-Csv -NoType $directory\Software-$td.csv
        wLog "Info:  Export of software information from the WMI provider for $alias was successful"
    }
    Catch
    {
        wLog "Error:  Exporting of the software information from the WMI provider was not successful for $alias"
        wLog $Error
    }

    #Export SOFTWARE INFORMATION from the registry
    Try
    {
        wLog "Info:  Exporting software information from the registry for $alias"
        $Uninstall_List | export-csv -NoType $directory\Uninstall_List-$td.csv
        wLog "Info:  Export of software information from the registry for $alias was successful"
    }
    Catch
    {
        wLog "Error:  Exporting of the software information from the registry was not successful for $alias"
        wLog $Error
    }
}

Function Get-RemoteProgram {
<#
.Synopsis
Generates a list of installed programs on a computer

.DESCRIPTION
This function generates a list by querying the registry and returning the installed programs of a local or remote computer.

#>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            Position=0)]
        [string[]]
            $ComputerName = $env:COMPUTERNAME,
        [Parameter(Position=0)]
        [string[]]$Property 
    )

    begin {
        $RegistryLocation = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\',
                            'SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\'
        $HashProperty = @{}
        $SelectProperty = @('ProgramName','ComputerName')
        $Use_Default = "Y"
        if ($Property) {
            $SelectProperty = $Property
            $Use_Default = "No"
        }
    }

    process {
        foreach ($Computer in $ComputerName) {
            $RegBase = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine,$Computer)
            foreach ($CurrentReg in $RegistryLocation) {
                if ($RegBase) {
                    $CurrentRegKey = $RegBase.OpenSubKey($CurrentReg)
                    if ($CurrentRegKey) {
                        $CurrentRegKey.GetSubKeyNames() | ForEach-Object {
                            if ($Property) {
                                foreach ($CurrentProperty in $Property) {
                                    $HashProperty.$CurrentProperty = ($RegBase.OpenSubKey("$CurrentReg$_")).GetValue($CurrentProperty)
                                }
                            }
                            if ($Use_Default="Y") {
                                $HashProperty.ComputerName = $Computer
                                $HashProperty.ProgramName = ($DisplayName = ($RegBase.OpenSubKey("$CurrentReg$_")).GetValue('DisplayName'))
                            }
                            if ($DisplayName) {
                                New-Object -TypeName PSCustomObject -Property $HashProperty |
                                Select-Object -Property $SelectProperty
                            } 
                        }
                    }
                }
            }
        }
    }
}


#start date
$st = get-date -format "yyyyMMdd-HH.mm.ss"

#Arguments passed in from the script being called
$directory = ""

If ($args.Length -eq 1)
{
     $directory = $args[0]
}
ElseIf ($directory -eq "")
{
    # Default output location of the file unless being overuled by input when script is called
    $directory = (Get-Item -Path ".\" -Verbose).FullName
} 
      
#Get the list of computers to interrogate from a file source
$var = $directory + "\hostnames.csv"
#Test the path exists, if not default to local machine.
If (Test-Path -Path $var)
{
    $ComputerList = Import-Csv $var

    #Get the column names - This could vary e.g. "Host", "hostname" 
    $csvColumnNames = (Get-Content $var | Select-Object -First 1).split(",")
    $hostname = $csvColumnNames[0]
    $alias = $csvColumnNames[1]
}
else
{
     $ComputerList = $env:computername
     #This needs to be set to LOCAL for our check later on
     $alias = "LOCAL"
}



#Test to see if the directory path exists, if it doesn't, then create it
If (!(Test-Path -Path $directory))
{
    New-Item $directory -ItemType directory
}

#Log path
$logDirectory = "$directory\Logs\"
#Test to see if the Log path exists, if it doesnt, create it.
If (!(Test-Path -Path $logDirectory))
{
    New-Item $logDirectory -ItemType directory
}

#Creat new log file for this run through
$logfile = New-Item "$directory\Logs\Log-$st.txt" -ItemType File
$logPath = $logfile

wLog "================================================================"
wLog "Info:  Starting PowerShell Log....  "
wLog "================================================================"

wLog "Info:  Input source (Computer List): $var"
wLog "Info:  Output source (csv): $directory"
wLog "Info:  Logfile location: $logfile"

#Check to make sure the computers loaded properly
If ($ComputerList -eq $env:computername)
{
    $compCount = 1;
}
else
{
    $compCount = $ComputerList.$hostname.count
}

If ($compCount -lt 1)
{
    wLog "Error: Failed to load computer list. The computer list count is: $compCount"
}
else
{
    wLog "Info:  Computer List Count: $compCount"
}

Inventory-Main

wLog "================================================================"
wLog "Info:  End of PowerShell Log....  "
wLog "================================================================"