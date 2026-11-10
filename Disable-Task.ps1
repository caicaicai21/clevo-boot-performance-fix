# Elevated PowerShell required. Disables only; does not delete files or undo an already-issued hardware request.
$ErrorActionPreference='Stop'
$p=New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if(-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'Administrator PowerShell required.'}
Disable-ScheduledTask -TaskName 'CLEVO_Entertainment_Boot_Test'|Select-Object TaskName,State
Write-Host 'Disabled. Original OEM software and services were not changed. This does not undo a mode request already issued.'
