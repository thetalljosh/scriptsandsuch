# domain name should be only first prefix - netbios name followed by back slash
$domain = "NetBios\"
$user = "username"
$name = $domain + $user
$serverlist = (Get-ADComputer -Filter {enabled -eq $true -and operatingsystem -like "*server*"}).name
$arraylist = new-object System.Collections.Arraylist
foreach ($server in $serverlist) {
    $foundtask = cmd.exe /c schtasks.exe /query /s $server /V /FO CSV | CONVERTFROM-CSV | Where-Object {$_."Run As User" -like "$name"} | Select-Object -Property @{N="HostName";E={$_.HostName}},@{N="TaskName";E={$_.TaskName.split("\")[-1]}}
    $global:arraylist += $foundtask
}
$arraylist