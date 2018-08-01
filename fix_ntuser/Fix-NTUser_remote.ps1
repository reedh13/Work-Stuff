function Fix-NTUser {
    param (
        [string]$ComputerName
    )
    $ErrorActionPreference = "SilentlyContinue"
    $Report = $Null
    $Path = "\\$ComputerName\c$\Users"
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

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" `"$args`"" -Verb RunAs; exit }

#WORK
$comp_name = Read-Host -Prompt "Enter computer name"
Fix-NTUser($comp_name)