# By Reed Hansen July 2018
# Purpose: View the currently logged in users of a remote computer

#DECLARE FUNC
function Set-Size {
    Param(
        [Parameter(Mandatory=$False,Position=0)]
        [int]$Height = 30,
        [Parameter(Mandatory=$False,Position=1)]
        [int]$Width = 90
    )
    $Console = $host.ui.rawui
    $Buffer  = $Console.BufferSize
    $ConSize = $Console.WindowSize
    If ($Buffer.Width -gt $Width ) {
       $ConSize.Width = $Width
       $Console.WindowSize = $ConSize
    }
    $Buffer.Width = $Width
    $ConSize.Width = $Width
    $Buffer.Height = 250
    $Console.BufferSize = $Buffer
    $ConSize = $Console.WindowSize
    $ConSize.Width = $Width
    $ConSize.Height = $Height
    $Console.WindowSize = $ConSize
}

function Test-MyConnection {
    param (
        [string]$computer_name
    )
    if (Test-Connection "$computer_name" -quiet) {
        return $True
    } else {
        Write-Host "$computer_name is OFFLINE." -ForegroundColor Red
        return $False
    }
}

#Get admin
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" `"$args`"" -Verb RunAs; exit }

#Set console
Set-Size

#WORK
do {
    $computer = read-Host "`n`nEnter computer name"
    if (Test-MyConnection "$computer") {
        psexec \\$computer quser
    }
} until ($x = 0)