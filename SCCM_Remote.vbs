OPTION EXPLICIT
 
DIM strComputer, regPath, regValue, regData, objReg
 
CONST HKEY_LOCAL_MACHINE = &H80000002 
 
strComputer = InputBox("Enter computer name: ","SCCM Remote Control")  
  
If strComputer <> "" Then
 
  Set objReg = GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & strComputer & "\root\default:StdRegProv") 
  
  regPath = "SOFTWARE\Microsoft\SMS\Client\Client Components\Remote Control"
 
  regValue = "Permission Required"
 
  'remove old key 
  objReg.DeleteValue HKEY_LOCAL_MACHINE,regPath,regValue  
 
  regData = 0
 
  'create new key
  objReg.SetDWORDValue HKEY_LOCAL_MACHINE,regPath,regValue,regData 
 
  Msgbox "Remote Control Granted!",64 ,"Alert"
 
End If
 
 
'clear session
strComputer = ""
regPath = ""
regValue = ""
regData = ""
objReg = ""