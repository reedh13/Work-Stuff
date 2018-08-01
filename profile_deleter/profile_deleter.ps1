# By Reed Hansen June 2018
# Purpose: Remove old profiles or a specific profile from remote computers

#############################
#DO NOT EDIT BELOW THIS LINE#
#############################

#TO DO:
#Parallelization of 2?

#GET ADMIN
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" `"$args`"" -Verb RunAs; exit }

#DECLARE FUNC
function Set-Size {
    Param(
        [Parameter(Mandatory=$False,Position=0)]
        [int]$Height = 50,
        [Parameter(Mandatory=$False,Position=1)]
        [int]$Width = 100
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
           [string]$Title = 'Profile Deleter'
     )
     Clear-Host
     Write-Host "================ $Title ================"
     Write-Host "1: Press '1' to work with a single computer."
     Write-Host "2: Press '2' to work with a list of computers."
     Write-Host "3: Press '3' to delete a specific profile from a computer."
     Write-Host "Q: Press 'Q' to quit."
}

function Test-SSO {
    param (
        [string]$computer_name
    )
    if ((test-path \\$computer_name\c$\Sentillion\Vergence_Shared-Standard.txt) -or (test-path \\$computer_name\c$\Sentillion\Vergence_Shared-Public.txt) -or (test-path \\$computer_name\c$\Sentillion\Vergence_Shared-OR.txt)) {
        Write-Host "$computer_name is a Shared-SSO device and has been skipped." -ForegroundColor Red
        return $True
    } Else {
        return $False
    }
}

function Test-MyConnection {
    param (
        [string]$computer_name
    )
    if (Test-Connection "$computer_name" -quiet) {
        Write-Host "$computer_name is online." -ForegroundColor Green
        return $True
    } else {
        Write-Host "$computer_name is OFFLINE." -ForegroundColor Red
        return $False
    }
}

function Test-PCName {
    param (
        [string]$computer_name
    )
    if ((($computer_name -like "UPH??????") -or ($computer_name -like "IHS??????")) -or ($computer_name -like '10.*')) {
        return $True
    } else {
        Write-Host "Bad name. Name does not begin with IHS, UPH, or 10.`nCheck name of: $computer_name" -ForegroundColor Red
        return $False
    }
}

function Fix-NTUser {
    param (
        [string]$computer_name
    )
    $ErrorActionPreference = "SilentlyContinue"
    $Report = $Null
    $Path = "\\$computer_name\c$\Users"
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
    #Write-Host $UserName $DatTime
    #Write-Host (Get-item $Path\$UserName -Force).LastWriteTime
    $Report = $Report + "$UserName`t$DatTime`r`n"
    $Dat = $Null
    }
}

#DECLAR VAR
$completed = 0
$completed_list
$fail_connect = 0
$fail_connect_list
$fail_sso = 0
$fail_sso_list

#WORK
Set-Size

do {
	Show-Menu
    $input = Read-Host "Make a selection"

	switch ($input) {
        '1' {
            Clear-Host
            $single_name = Read-Host -Prompt "Enter the computer name"
            if (Test-PCName "$single_name") {
                if (Test-MyConnection "$single_name") {
                    if (!(Test-SSO -computer_name $single_name)) {
                        Fix-NTUser $single_name
                        #call of delprof2- real args "/u", "/c:\\$single_name", "/d:XXX", "/ed:pcadmin", "/ed:DefaultAppPool", "/ed:defaultuser0", "/ed:ADMINI~1"
                        Start-Process -FilePath $PSScriptRoot\DelProf2.exe -ArgumentList "/u", "/c:\\$single_name", "/d:90", "/ed:pcadmin", "/ed:DefaultAppPool", "/ed:defaultuser0", "/ed:ADMINI~1" -NoNewWindow -Wait
                    }
                }
            }

        } '2' {
            Clear-Host
            if (test-path $PSScriptRoot/delete_profiles.txt) {
                $input_list = Get-Content -Path $PSScriptRoot/delete_profiles.txt
                foreach ($computer in $input_list) {
                    if (Test-PCName "$computer") {
                        if (Test-MyConnection "$computer") {
                            if (!(Test-SSO -computer_name "$computer")) {
                                Fix-NTUser $computer
                                #call of delprof2- real args "/u", "/c:\\$single_name", "/d:XXX", "/ed:pcadmin", "/ed:DefaultAppPool", "/ed:defaultuser0", "/ed:ADMINI~1"
                                Start-Process -FilePath $PSScriptRoot\DelProf2.exe -ArgumentList "/u", "/c:\\$computer", "/d:90", "/ed:pcadmin", "/ed:DefaultAppPool", "/ed:defaultuser0", "/ed:ADMINI~1" -NoNewWindow -Wait
                                $completed++
                                $completed_list += $completed_list + $computer
                            } Else {
                                $fail_sso++
                                $fail_sso_list += $fail_sso_list + $computer
                            }
                        } Else {
                            $fail_connect++
                            $fail_connect_list += $fail_connect_list + $computer
                        }
                        $input_list = $input_list | Where-Object {$_ -ne $computer}
                    }
                }
                #FINAL OUTPUT
                $input_list | Out-File delete_profiles.txt -force
                $timestamp = get-date -UFormat "%m_%d_%Y_T%T" | ForEach-Object {$_ -replace ":" , "_"}
                $completed_list | Out-File $PSScriptRoot\deletion_successful_$timestamp.txt
                Write-Host "Successful computers: [$completed]`n" -ForegroundColor Green
                Write-Host "These computer names are available in deletion_successful.txt.`n" -ForegroundColor Green
                if ($fail_sso_list) {
                    $fail_sso_list | Out-File $PSScriptRoot\deletion_failed_sso_$timestamp.txt
                    Write-Host "SSO computers: [$fail_sso]" -ForegroundColor Red
                    Write-Host "These computer names have been placed in deletion_failed_sso.txt.`n" -ForegroundColor Red
                }
                if ($fail_connect_list) {
                    $fail_sso_list | Out-File $PSScriptRoot\deletion_failed_connection_$timestamp.txt
                    Write-Host "Offline computers: [$fail_connect]" -ForegroundColor Red
                    Write-Host "These computer names have been placed in deletion_failed_connection.txt.`n" -ForegroundColor Red
                }
            } else {
                Write-Host "Computer list 'delete_profiles.txt' not found.`nPlease ensure it exists in the same directory as this script.`n" -ForegroundColor Red
            }

        } '3' {
            Clear-Host
            $single_name = Read-Host -Prompt "Enter the computer name"
            $target_profile = Read-Host -Prompt "Enter the target profile name"
            if (Test-PCName) {
                if (Test-MyConnection "$single_name") {
                    if (!(Test-SSO -computer_name $single_name)) {
                        if (Test-Path \\$single_name\c$\users\$target_profile) {
                            Start-Process -FilePath $PSScriptRoot\DelProf2.exe -ArgumentList "/u", "/q", "/c:\\$single_name", "/id:$target_profile" -NoNewWindow -Wait
                        } else {
                            Write-Host "Cannot find the profile named $target_profile on $single_name." -ForegroundColor Red
                        }
                    }
                }
            }

        } 'Q' {
            return
        }
    }
    pause
} until ($input -eq 'Q')