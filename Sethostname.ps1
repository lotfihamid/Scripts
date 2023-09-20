$computerName = (Get-WmiObject Win32_ComputerSystem).Name
$name = (New-Object System.Net.WebClient).DownloadString("http://169.254.169.254/latest/meta-data/hostname").Split(".")[0]
Rename-Computer -ComputerName $computerName -NewName $name -Restart
