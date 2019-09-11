#Find folders that a group has access perms on, Checks if inherited

#Variables
$folderRoot = "\\server\share"
$group = "Authenticated Users"
$output = "C:\$group Perms List.txt"

#Script
$folders = Get-ChildItem $folderRoot -Recurse | ?{ $_.PSIsContainer } | Select-Object -ExpandProperty fullname
$requested = @()

#List All Folders in console (optional)
$folders.foreach({$_})

#Check Perms and Copy to File
foreach ($folder in $folders){

    $access = ((Get-Acl $folder).Access)

    ($access.ForEach({if ($_.IdentityReference -like  "*$group*") {"`"$folder`" contains $group, Inherited: " + $_.IsInherited}})).foreach({ $_ | out-file $output -Append})

}