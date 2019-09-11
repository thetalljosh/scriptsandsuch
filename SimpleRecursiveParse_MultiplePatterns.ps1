 
$location = "\\Usvapdna-a005a\rritinfo$\Measurement\Mitutoyo\Data\Grind\MLArchive" #Path to PARENT folder - search is recursive to all child paths

#DONT CHANGE BELOW THIS LINE

Get-ChildItem $location -recurse |

Select-String -Pattern '@', '%'  |

Out-File "C:\ATS\Josh\MakinoNRPSearchOutput.csv" 