#Author: Josh Lambert
#Disclaimer: If this doesn't work or causes issues, blame Losh Jambert

$DownloadURL="http://www.java.com/en/download/manual.jsp"
$32bit="Download Java software for Windows Offline"
$64bit="Download Java software for Windows (64-bit)"
$UserAgent="Mozilla/5.0 (Windows NT 6.1; WOW64; rv:25.0) Gecko/20100101 Firefox/25.0"
$InstallString="/s"
$UninstallSwitches="/qn /norestart"
$UninstallDisplayNameWildcardString="Java*"
$UninstallTimeout="45"
$Temp = "C:\Temp"
$TempTest = if(!(test-path $temp)){new-item -itemtype directory -path $temp -force}
$outpath = "$TEMP\javaupdater.exe"
$wc = New-Object System.Net.WebClient
$JavaTempFilePath = "C:\Temp\javaupdater.exe"

function MyLog {
    param([string] $Message)
    (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') + "`t$Message" | Out-File $TEMP\JavaUpdate.log -Append
    Write-Host (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') "`t$Message"
}  
 
        
        if ($env:PROCESSOR_ARCHITECTURE -eq 'x86') {
            $Url = $32bit
                $32bitDL = (((Invoke-WebRequest -UseBasicParsing -uri $DownloadURL).links | Where-Object {$_.title -eq $32bit}).href | select -First 1) 
                
                $wc.DownloadFile($32bitDL, $outpath)
               # Invoke-WebRequest $32bitDL | out-file $TEMP\javaupdater.exe -Force

        }
        
        elseif ($env:PROCESSOR_ARCHITECTURE -eq 'AMD64') {
            
            $Url = $64bit
            $64bitDL = (((Invoke-WebRequest -UseBasicParsing -uri $DownloadURL).links | Where-Object {$_.title -eq $64bit}).href | select -First 1) 
            $wc.DownloadFile($64bitDL, $outpath)
            #Invoke-WebRequest $64bitDL | out-file $TEMP\javaupdater.exe -Force
           

        }

        if(!(test-path $JavaTempFilePath)){MyLog "Java download failed.";exit 10}
        elseif(test-path $JavaTempFilePath){MyLog "Java downloaded to $JavaTempFilePath"}
    


# Uninstall stuff. Try to uninstall everything whose DisplayName matches the wildcard string in the config file.
    
    $UninstallRegPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
    $RegUninstallString = Get-ChildItem $UninstallRegPath | ForEach-Object {
        Get-ItemProperty ($_.Name -replace '^HKEY_LOCAL_MACHINE', 'HKLM:') # ugh...
    } | Where-Object { $_.DisplayName -like $UninstallDisplayNameWildcardString } | Select -ExpandProperty UninstallString
    
    $JavaGUIDs = @()
    $RegUninstallString | ForEach-Object {
        if ($_ -match '(\{[^}]+\})') {
            $JavaGUIDs += $Matches[1]
        }
    }
    
    $Failed = $false
    # Now this is a fun error on uninstalls:
    # "There was a problem starting C:\Program Files\Java\jre7\bin\installer.dll. The specified module could not be found"
    # So... Start the uninstall in a job, return the exit code (if/when done), wait for the specified number of seconds,
    # and kill rundll32.exe if it takes longer than the timeout... ugh. Oracle, I curse you! Currently testing with 7u45,
    # which consistently does this if it's installed silently more than once ("reconfigured" (and broken) the second time).
    foreach ($JavaGUID in $JavaGUIDs) {
        $Result = Start-Job -Name UninstallJob -ScriptBlock {
            Start-Process -Wait -NoNewWindow -PassThru -FilePath msiexec.exe -ArgumentList $args
            } -ArgumentList ("/X$JavaGUID " + $UninstallSwitches)
        
        Wait-Job -Name UninstallJob -Timeout $UninstallTimeout | Out-Null
        $Timeout = 0
        while (1) {
            
            if ((Get-Job -Name UninstallJob).State -eq 'Completed') {
                
                MyLog "Presumably successfully uninstalled Java with GUID: $JavaGUID"
                break
                
                           }
            # Let's kill rundll32.exe ... ugh.
            else {
                Get-Process -Name rundll32 -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 10
                $Timeout += 10
                if ($Timeout -ge 40) {
                    MyLog "Timed out waiting for rundll32.exe to die or job to finish."
                    $Failed = $true
                    break
                }
            }
            
            Wait-Job -Name UninstallJob -Timeout $UninstallTimeout | Out-Null
            
        } # end of infinite while (1)

        Remove-Job -Name UninstallJob
        
    } # end of foreach JavaGUID

    if ($Failed) { MyLog "Exiting because a Java uninstall previously failed."; exit 10 }
    


try {
    MyLog "Attempting to install Java"
    $Install = Start-Process -Wait -NoNewWindow -PassThru -FilePath $JavaTempFilePath -ArgumentList $InstallString -ErrorAction Stop

    if ($Install.ExitCode -eq 0) {
        MyLog "Successfully updated Java."
        if ($Env:PROCESSOR_ARCHITECTURE -eq 'x86' -or $Force32bit) { $Id }
        else { $Id  }
        MyLog "Cleaning Up!"
        if (Test-Path $JavaTempFilePath){rm $JavaTempFilePath -Recurse -Force}
    }
    else {
        MyLog ("Failed to update Java. Exit code of installer: " + $Install.ExitCode)
    }

}
catch {
    MyLog "Failed to install Java: $($Error[0])"
}
