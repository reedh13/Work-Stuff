#July 2018 - Reed Hansen
#Purpose: Reset the 'last modified' date of user profiles to the last true login time
#Notes: This script must be run locally on the computer containing the profiles you wish to update
function Fix-NTUser {
    $ErrorActionPreference = "SilentlyContinue"
    $Report = $Null
    $Path = "c:\Users"
    $UserFolders = $Path | Get-ChildItem -Directory
    ForEach ($UserFolder in $UserFolders)
    {
    $UserName = $UserFolder.Name
    If (Test-Path "$Path\$UserName\NTUSer.dat") {
        $Dat = Get-Item "$Path\$UserName\NTUSer.dat" -force
        $DatTime = $Dat.LastWriteTime
        If ($UserFolder.Name -ne "default") {
            $Dat.LastWriteTime = $UserFolder.LastWriteTime
        }
    }
    Write-Host $UserName $DatTime
    Write-Host (Get-item $Path\$UserName -Force).LastWriteTime
    $Report = $Report + "$UserName`t$DatTime`r`n"
    $Dat = $Null
    }
}


#WORK
Fix-NTUser