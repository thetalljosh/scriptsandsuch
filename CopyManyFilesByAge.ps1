#using a hash table to relate pc name to machine number
$paths = @{
            
            
            }

 
$SourceDir = "C:\test"
$destinationdir = "C:\test"
$robooptions = @('/R:0', '/S', '/MT:8', '/Log+:"C:\test\MoveLog.txt"')

Write-Host "Copying files from machines to network directory." -ForegroundColor red -BackgroundColor white
foreach($path in $paths.GetEnumerator()){

$src = $path.Name
$dst = $path.Value
$copysource = "$SourceDir\$src"
$copydest = "$destinationdir\$dst"
$cmdArgs = @("$copysource", "$copydest", $robooptions)

robocopy @cmdArgs
#start-sleep -seconds 10
}

Write-Host "Moving files into respective  directories." -ForegroundColor red -BackgroundColor white
foreach($path in $paths.GetEnumerator()){

$src = $path.Name
$dst = $path.Value

$copydest = "$destinationdir\$dst\"
 Get-ChildItem $copydest -Recurse | where-object {!$_.PSIsContainer} | ForEach-Object ($_) {
		$SourceFile = $_.FullName
		$DestinationFile = $copydest + $_
		if (Test-Path $DestinationFile) {
			$i = 0
			while (Test-Path $DestinationFile) {
				$i += 1
				$DestinationFile = $copydest + $_.basename + "_" + $i + $_.extension
			}
		} else {
			move-Item -Path $SourceFile -Destination $DestinationFile -Force -ErrorAction SilentlyContinue
		}
		move-Item -Path $SourceFile -Destination $DestinationFile -Force -ErrorAction SilentlyContinue
	}
}

#this commented block will append the serial number as a column in each file
#foreach($path in $paths){
#$copydest = "$destinationdir\$path\"
# Get-ChildItem $copydest -Recurse | where-object {!$_.PSIsContainer} | ForEach-Object ($_) {
# $CSV = Import-CSV -Path $_.FullName -Delimiter ","
# $Filename = $_.Name
#
# $CSV =  $CSV | Select-Object *,@{N='Filename';E={$FileName}} | Export-CSV $_.FullName -NTI -Delimiter ","
# }
# }
#clean up the empty folders
$copydest = $destinationdir
Write-Host "Removing empty folders." -ForegroundColor red -BackgroundColor white
invoke-command -scriptblock { dir $destinationdir -Directory -recurse | where {-NOT $_.GetFiles("*","AllDirectories")} |  del -recurse } 

#combine the files into one big ugly file



Write-Host "Combining data into one file." -ForegroundColor red -BackgroundColor white
foreach($path in $paths.GetEnumerator()){

$src = $path.Name
$dst = $path.Value
$copydest = "$destinationdir\$dst\"
$combinedfilename = "$copydest\${dst}_OEE_$(get-date -f yyyy-MM-dd).csv"

copy $copydest\*.csv $combinedfilename
}


Write-Host "Removing unnecessary files." -ForegroundColor red -BackgroundColor white
foreach($path in $paths.GetEnumerator()){

$src = $path.Name
$dst = $path.Value
$clearJunk = Get-ChildItem "$destinationdir\$dst" -recurse -file | Where {$_.BaseName -notlike "*OEE*"}
foreach($file in $clearJunk) {Remove-Item $file.FullName}
} 



