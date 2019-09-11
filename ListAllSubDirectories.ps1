$SearchMe = "C:\Partrtn\AAMF Routines\Results"
$WhereToSaveOutput = "C:\Audit"

New-Item -ItemType Directory -Force -Path "C:\Audit" | Out-Null
Get-ChildItem -Path $SearchMe -Directory -Recurse |
    Select-Object parent,name,lastwritetime,fullname |
    Export-CSV "$WhereToSaveOutput\PartProduced $(get-date -f yyyy-MM-dd).csv" -NoTypeInformation | Out-Null 

    