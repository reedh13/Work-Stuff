# By Reed Hansen, August 2018
# Purpose: Constantly pings a specific computer then produces a popup when it does come online.

function Set-Size {
    # Purpose: Set size of console window
    # Use: Change Height or Width variables manually or through positional arguments
    Param(
        [Parameter(Mandatory=$False,Position=0)]
        [int]$Height = 10,
        [Parameter(Mandatory=$False,Position=1)]
        [int]$Width = 50
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

$host.ui.RawUI.WindowTitle = "Ping-Popup Tool"
Set-Size

$comp_name = Read-Host "Enter computer name"
$msg = "Computer $comp_name hsa come online (•‿•)"
$i = 1

Write-Host "`nNow monitoring network presence of $comp_name...`n" -ForegroundColor Green
while ($True) {
    Write-Host "Still looking! Presence check #$i"
    if (Test-Connection -ComputerName $comp_name -Count 2 -Delay 15 -Quiet) {
        Invoke-WmiMethod -Path Win32_Process -Name Create -ArgumentList "msg * $msg"
        break
    }
    $i++
}