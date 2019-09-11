@echo off

tasklist | find /I "notepad.exe"
if errorlevel 1 (
	start notepad.exe
	mshta javascript:alert^("Please do not close Notepad!"^);close^(^);
) else exit