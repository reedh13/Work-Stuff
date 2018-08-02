# READ ME - By Reed Hansen May 2018
# Purpose: To add TCP/IP printers remotely en masse

# How to Use
# 1. Save this script to your desktop
# 2. If adding a printer to multiple computers, move 'add_printer.txt' to your desktop and enter the computer names
# 3. Edit driver name below if necessary
$Driver = "Lexmark Universal v2 PS3"
# 4. Save this file
# 5. Run this file - Right click it and press "Run with PowerShell"
# 6. Proceed through the script

#############################
#DO NOT EDIT BELOW THIS LINE#
#############################

# To do:
# Add printer > scan for users > insert startup script to set as default > delete script after running (abandoned)
# Add driver selection?
# Add module to remove all tcp/ip printers?

#DECLARE FUNC
function Set-Size {
    Param(
        [Parameter(Mandatory=$False,Position=0)]
        [int]$Height = 30,
        [Parameter(Mandatory=$False,Position=1)]
        [int]$Width = 75
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

function Show-Menu {
    param (
        [string]$Title = 'Printer Multitool'
    )
    Clear-Host
    Write-Host "================ $Title ================"
    Write-Host "1: Press '1' to add a printer."
    Write-Host "2: Press '2' to add a printer to a list of computers."
    Write-Host "3: Press '3' to view or delete printers."
    Write-Host "Q: Press 'Q' to quit."
}

function Show-InteractivePrinterMenu {
    param (
        [Parameter(Mandatory=$True, Position=0)]
        [string]$ComputerName
    )
    #Initialize form window and objects
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Printer Deletion'
    $form.Size = New-Object System.Drawing.Size(900,325)
    $form.StartPosition = 'CenterScreen'
    $form.FormBorderStyle = 'FixedSingle'

    #Form buttons
    $OKButton = New-Object System.Windows.Forms.Button
    $OKButton.Location = New-Object System.Drawing.Point(25,250)
    $OKButton.Size = New-Object System.Drawing.Size(75,25)
    $OKButton.Text = 'Delete'
    $OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.AcceptButton = $OKButton
    $form.Controls.Add($OKButton)
    $CancelButton = New-Object System.Windows.Forms.Button
    $CancelButton.Location = New-Object System.Drawing.Point(150,250)
    $CancelButton.Size = New-Object System.Drawing.Size(75,25)
    $CancelButton.Text = 'Cancel'
    $CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.CancelButton = $CancelButton
    $form.Controls.Add($CancelButton)

    #Form label
    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(10,10)
    $label.Size = New-Object System.Drawing.Size(800,20)
    $label.Font = New-Object System.Drawing.Font("Arial",12,[System.Drawing.FontStyle]::Bold)
    $label.Text = "Check the box to delete the printer.      NOTE: Only TCP/IP and USB printers will appear in this list."
    $form.Controls.Add($label)

    #Form list
    $listBox = New-Object System.Windows.Forms.ListView
    $listBox.Location = New-Object System.Drawing.Point(10,40)
    $listBox.Size = New-Object System.Drawing.Size(865,200)
    $listBox.Height = 200
    $listBox.CheckBoxes = $True
    $listBox.View = 'Details'
    $listBox.FullRowSelect = $true
    $listBox.Font = New-Object System.Drawing.Font("Arial",12,[System.Drawing.FontStyle]::Regular)
    $listBox.Columns.Add("Printer Name", 180) | Out-Null
    $listBox.Columns.Add("Port", 140) | Out-Null
    $listBox.Columns.Add("Status", 75) | Out-Null
    $listBox.Columns.Add("Driver Name", 460) | Out-Null
    #Selects only TCP/IP or USB printers for display. "DeviceType" filter is an issue with duplicate printers appearing from Win7 machines
    #You do not want to remove Windows-integrated ports like COM, SHRFAX, NUL
    foreach ($printer in Get-Printer -ComputerName $ComputerName | Where-Object {($_.DeviceType -eq "Print") -and (($_.PortName.Contains(".")) -or ($_.PortName.StartsWith("USB")))}) {
        $name = $printer.Name
        $item = New-Object System.Windows.Forms.ListViewItem("$name")
        $listBox.Items.Add($item) | Out-Null
        $item.SubItems.Add($printer.PortName) | Out-Null
        $item.SubItems.Add($printer.PrinterStatus.ToString()) | Out-Null
        $item.SubItems.Add($printer.DriverName) | Out-Null
    }

    #Form finalize and display
    $form.Controls.Add($listBox)
    $form.Topmost = $true
    $result = $form.ShowDialog()

    #Deletion
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        foreach ($selected in $listBox.CheckedItems) {
            $name = $selected.Text
            $portname = $selected.SubItems[1].Text.ToString()
            Remove-Printer -ComputerName $ComputerName -Name "$name"
            Remove-PrinterPort -ComputerName $ComputerName -Name "$portname"
        }
    }
}

Set-Size

do {
    Clear-Host
    Show-Menu
    $input = Read-Host "Make a selection"

    #SINGLE CONDITION
    switch ($input) {
        '1' {
            Clear-Host
            $ip = Read-Host -prompt "`nEnter printer IP address"
            $name = Read-Host -Prompt "`nEnter printer name"
            #PRINTER CONNECTION TEST
            "`nTesting connection to printer..."
            if (Test-Connection "$ip" -Quiet) {
                Write-Host "$ip is online.`n" -ForegroundColor Green
            } Else {
                Write-Host "$ip is offline.`n" -ForegroundColor Red
                Read-Host "Ensure the printer is powered on and connected to the network."
            }
            $comp_name = Read-Host -Prompt "Enter computer name"
            if (Test-Connection "$comp_name" -Quiet) {
                Add-PrinterPort -name "$ip" -ComputerName "$comp_name" -PrinterHostAddress "$ip" -SNMP 1 -SNMPCommunity "public"
                Add-Printer -ComputerName $comp_name -Name "$name" -DriverName "$Driver" -PortName "$ip"
                Write-Host "`nPrinter added to $comp_name" -ForegroundColor Green
            } else {
                Write-Host "`nFailed to add printer to $comp_name.`nEnsure the computer is powered on and connected to the network." -ForegroundColor Red
            }


        } '2' {
            Clear-Host
            $ip = Read-Host -prompt "`nEnter printer IP address"
            $name = Read-Host -Prompt "`nEnter printer name"
            #PRINTER CONNECTION TEST
            "`nTesting connection to printer..."
            if (Test-Connection "$ip" -Quiet) {
                Write-Host "$ip is online.`n" -ForegroundColor Green
            } Else {
                Write-Host "$ip is offline.`n" -ForegroundColor Red
                Read-Host "Ensure the printer is powered on and connected to the network."
            }
            if (Test-Path add_printer.txt) {
                $list = Get-Content -Path add_printer.txt
                foreach ($comp_name in $list) {
                    if (Test-Connection "$comp_name" -Quiet) {
                        Add-PrinterPort -name "$ip" -ComputerName "$comp_name" -PrinterHostAddress "$ip" -SNMP 1 -SNMPCommunity "public"
                        Add-Printer -ComputerName $comp_name -Name "$name" -DriverName "$Driver" -PortName "$ip"
                        $list = $list | Where-Object {$_ -ne $comp_name} #SEARCH & DELETION FROM LIST
                        Write-Host "Printer added to $comp_name" -ForegroundColor Green
                    } else {
                        Write-Host "$comp_name is OFFLINE and has been skipped." -ForegroundColor Red
                    }
                }
                $list | Out-File add_printer.txt -Force
                Write-Host "`nPrinter additions completed."
            } else {
                Write-Host "`nCannot find 'add_printer.txt.'`nPlease ensure it exists in the same directory as this script." -ForegroundColor Red
            }

        } '3' {
            $comp_name = Read-Host -Prompt "`nEnter computer name"
            if (Test-Connection $comp_name -Quiet) {
                Show-InteractivePrinterMenu -ComputerName $comp_name
            } else {
                Write-Host "$comp_name is offline." -ForegroundColor Red
            }

        } 'Q' {
            return
        }
    }
    pause
} until ($input -eq 'Q')