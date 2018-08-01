$name = read-host "Enter computer name"
$msg = read-host "Enter message"
Invoke-WmiMethod -Path Win32_Process -Name Create -ArgumentList "msg * $msg" -ComputerName $name