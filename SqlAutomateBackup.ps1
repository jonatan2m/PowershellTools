﻿ #Write-Host "Updating  ExecutionPolicy "
 #Set-ExecutionPolicy -ExecutionPolicy RemoteSigned

. ($PSScriptRoot + '\SqlBackupRestore.ps1')

$items = Get-Content -Raw -Path  ($PSScriptRoot + '\dbinfo.json') | ConvertFrom-Json
	
foreach($i in $items){
    Write-Host "Starting backup to " $i.alias
    New-SqlBackup -Instance $i.server -Login $i.username -Password $i.passw -BackupDirectory $i.path -Database $i.dbName
}

