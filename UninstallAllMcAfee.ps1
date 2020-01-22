#this param function block forces the script to run under elevated token

param([switch]$Elevated)

function Test-Admin {
  $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
  $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if ((Test-Admin) -eq $false)  {
    if ($elevated) 
    {
        # tried to elevate, did not work, aborting
    } 
    else {
        Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -noexit -file "{0}" -elevated' -f ($myinvocation.MyCommand.Definition))
}

exit
}

'running with full privileges'
#first, define our variables. the agent removing string will always be a constant 
$agentuninstaller="""C:\Program Files\McAfee\Agent\x86\FrmInst.exe"" /remove=agent"
$desktoppath = [Environment]::GetFolderPath("Desktop")
#gotta make sure the FrmInst.exe package exists on the system to execute from it
$frmExist=(Test-Path "C:\Program Files\McAfee\Agent\x86\FrmInst.exe") 

if($frmExist) {

#after passing that check, run the /remove=agent switch to set mcafee as unmanaged
start-process -filepath "C:\windows\system32\cmd.exe" -wait -verb runas -ArgumentList '/c', '""C:\Program Files\McAfee\Agent\x86\FrmInst.exe""', '/remove=agent'

}

#query the registry for all mcafee software installed on the system

$McAfeeVer = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall  |
    Get-ItemProperty |
        Where-Object {$_.DisplayName -like "*McAfee*" } |
            Select-Object -Property DisplayName, UninstallString >>$desktoppath\InstalledMcAfee.txt
#grab the uninstallstrings from the above select-object and iterate over them

ForEach ($ver in $McAfeeVer) {

    If ($ver.UninstallString) {
 
        $uninst = $ver.UninstallString
        #call the uninstall strings in an elevated command prompt

        & start-process -filepath "C:\windows\system32\cmd.exe" -wait -verb runas -ArgumentList '/c', '""$uninst""' '/quiet' '/norestart'
       # & cmd /c $uninst /quiet /norestart
    }

}
