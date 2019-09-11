strFolder =  InputBox("Enter Parent Folder to Search Within")'This is the parent folder we want to search within
filesNewerThanDays = 11
set objFSO = CreateObject("Scripting.FileSystemObject")
set objShell = CreateObject("WScript.Shell")

strYear = Year(Date) 
strMonth = Month(Date) : If Len(m)=1 Then m = "0" & m : End If
strDay = Day(Date) : If Len(d)=1 Then d = "0" & d : End If
strMyDate = strYear & "." & strMonth & "." & strDay

If NOT (objFSO.FolderExists("C:\Audit\")) Then
	objFSO.CreateFolder("C:\Audit\")
End If
set objCSV = objFSO.OpenTextFile("C:\Audit\PartsProduced_Last" & filesNewerThanDays & "days-" & strMyDate & ".csv", 8, true, 0)


function OGPDir(strFolder, intAge)
    set objFolder = objFSO.GetFolder(strFolder)
    for each objFolder in objFolder.SubFolders
        strResults = strResults & OGPDir(objFolder.Path, intAge)

next
	set objFolder = objFSO.GetFolder(strFolder)
    for each objFolder in objFolder.SubFolders
		dtmDate = objFolder.DateLastModified
		intAge = DateDiff("d", dtmDate, Date)
        if intAge < filesNewerThanDays then strResults = strResults & objFolder.Path & "|" & objFolder.DateLastModified & vbNewLine
		
    exit for

next

    OGPDir = strResults

end function

strOGPDirs = OGPDir(strFolder, intAge)
'wscript.echo strOGPDirs

strHeader = """Folder"", ""Date Last Modified"""
objCSV.WriteLine strHeader

arrRows = split(strOGPDirs, vbNewLine)
for i = 0 to ubound(arrRows) - 1 'all but the last one.
arrData = split(arrRows(i), "|")
strName = arrData(0)
strDate = arrData(1)
strRow = """" & strName & """,""" & strDate & """"
objCSV.WriteLine strRow
next

objCSV.close

wscript.echo "Operation Complete. File located at C:\Audit\" 