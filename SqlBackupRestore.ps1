#region SQL Assemblies
add-type -AssemblyName "Microsoft.SqlServer.ConnectionInfo, Version=12.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91" -ErrorAction Stop
add-type -AssemblyName "Microsoft.SqlServer.Smo, Version=12.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91" -ErrorAction Stop
add-type -AssemblyName "Microsoft.SqlServer.SMOExtended, Version=12.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91" -ErrorAction Stop
add-type -AssemblyName "Microsoft.SqlServer.SqlEnum, Version=12.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91" -ErrorAction Stop
add-type -AssemblyName "Microsoft.SqlServer.Management.Sdk.Sfc, Version=12.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91" -ErrorAction Stop
#endregion SQL Assemblies


function New-SqlBackup(){
    param
    (
        [parameter(Mandatory=$true)]
        [String]
        $Instance,
        
        [parameter(Mandatory=$true)]
        [String]
        $Login,

        [parameter(Mandatory=$true)]
        [String]
        $Password,

        [parameter(Mandatory=$false)]
        [String]
        $Database,        

        [parameter(Mandatory=$false)]
        [String]        
        $BackupDirectory
    )
        
    $mySrvConn = new-object Microsoft.SqlServer.Management.Common.ServerConnection    
    $mySrvConn.ServerInstance=$Instance
    $mySrvConn.LoginSecure = $false
    $mySrvConn.Login = $Login
    $mySrvConn.Password = $Password

    $svr = new-Object Microsoft.SqlServer.Management.Smo.Server($mySrvConn)
    
    while(!$BackupDirectory){
        Write-Host 'Default Directory: ' $svr.Settings.BackupDirectory
        $BackupDirectory = (Read-Host -Prompt "Type the new path, if necessary:") | % {$_.Trim()}
        
        if(!$BackupDirectory){            
            $BackupDirectory = $svr.Settings.BackupDirectory
        }
    }
    
     while(!$Database){
        Write-Host $svr.Databases
        $Database = (Read-Host -Prompt "Type the database's name:") | % {$_.Trim()}
    }

    Write-Host 'Generating backup...'
    
    $dt = Get-Date -Format yyyyMMddHHmmss        
    $db = $svr.Databases[$database]
    $dbname = $db.Name

    $dbbk = new-object ('Microsoft.SqlServer.Management.Smo.Backup')
    $dbbk.Action = 'Database'

    $dbbk.BackupSetDescription = "Full backup of " + $dbname
    $dbbk.BackupSetName = $dbname + " Backup"
    $dbbk.Database = $dbname
    $dbbk.MediaDescription = "Disk"
    $dbbk.Devices.AddDevice($BackupDirectory + "\" + $dbname + "_db_" + $dt + ".bak", 'File')
    $dbbk.SqlBackup($svr.Name)
}

function New-SqlRestore(){
    param
    (
        [parameter(Mandatory=$true)]
        [String]
        $Instance,
          
        [parameter(Mandatory=$false)]
        [String]
        $Database,
        
        [parameter(Mandatory=$false)]
        [String]
        $FileName
    )

    $svr = new-Object Microsoft.SqlServer.Management.Smo.Server($Instance)
    
     while(!$Database){
        Write-Host $svr.Databases
        $Database = (Read-Host -Prompt "Type the database's name.") | % {$_.Trim()}
    }

    $bdir = $svr.Settings.BackupDirectory

    $dbbk = new-object ('Microsoft.SqlServer.Management.Smo.Backup')

    while(!$FileName){
        Write-Host (Get-ChildItem $bdir)
        $FileName = (Read-Host -Prompt "Type the filename:") | % {$_.Trim()}
    }
    Write-Host 'Restoring...'

    $BackupFile = Get-ChildItem $bdir -Filter $FileName | select -First 1
    
    Write-Host $BackupFile
    
    $db = $svr.Databases[$Database]
    
    $dbname = $db.Name
    
    $smoRestore = New-Object Microsoft.SqlServer.Management.Smo.Restore
    
    $smoRestore.PercentCompleteNotification = 10;    
    $smoRestore.Database = $dbname
    $smoRestore.NoRecovery = $false
    $smoRestore.ReplaceDatabase = $true
    $smoRestore.FileNumber = 0
    
    $bdi = new-object Microsoft.SqlServer.Management.Smo.BackupDeviceItem($BackupFile.FullName, [Microsoft.SqlServer.Management.Smo.DeviceType]::File)
    $smoRestore.Devices.Add($bdi)

    $svr.KillAllProcesses($dbname)
    $smoRestore.SqlRestore($svr)
}



