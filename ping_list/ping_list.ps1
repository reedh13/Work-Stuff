# READ ME - By Reed Hansen June 2018
# Purpose: To ping a list of computers more easily and more readably than the command line.

#


function Test-MyConnection {
    param (
        [string]$computer_name
    )
    if (Test-Connection "$computer_name" -quiet -Count 2) {
        Write-Host "$computer_name is online." -ForegroundColor Green
    } else {
        Write-Host "$computer_name is OFFLINE." -ForegroundColor Red
    }
}

$list = Get-Content ping_list.txt

Foreach ($computer in $list) {
    Test-MyConnection($computer)
}

pause