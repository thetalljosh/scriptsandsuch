@echo off

tasklist | find /I "imagename.exe"
if errorlevel 1 (
	("C:\imagename.exe"))
else exit
exit