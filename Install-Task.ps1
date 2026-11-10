# Run once in elevated x64 Windows PowerShell. Never runs the hardware request during install.
$ErrorActionPreference='Stop'
$p=New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if(-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'Administrator PowerShell required.'}
if(-not [Environment]::Is64BitProcess){throw '64-bit PowerShell required.'}
$cs=Get-CimInstance Win32_ComputerSystem
$cpu=Get-CimInstance Win32_Processor
if($cs.Manufacturer.Trim() -ne 'COLORFIRE' -or $cs.Model.Trim() -ne 'MEOW R16 24H' -or ($cpu.Name -join ' ') -notmatch '7845HX'){
 throw 'Only the COLORFIRE MEOW R16 24H / Ryzen 9 7845HX has been tested. Installation refused on other hardware.'
}
$source=Join-Path $PSScriptRoot 'ClevoEntertainmentBootV2.exe'
$hash='90365099794AAD0FB70CD8E463682A1C21929293B4008A7B0CDD34943A4BE621'
if((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -ne $hash){throw 'EXE differs from tested build; refusing installation.'}
$dll='C:\Program Files (x86)\ControlCenter\InsydeDCHU.dll'
if((Get-FileHash -LiteralPath $dll -Algorithm SHA256).Hash -ne '0D6AA0586C628BEA1B6BFE4D5B2941D68D603474338EB0BB79730F2410BF1721'){throw 'OEM DLL differs from tested version.'}
if((Get-AuthenticodeSignature -LiteralPath $dll).Status -ne 'Valid'){throw 'OEM DLL signature invalid.'}
$name='CLEVO_Entertainment_Boot_Test'
if(Get-ScheduledTask -TaskName $name -ErrorAction SilentlyContinue){throw 'Task already exists. Existing installation left unchanged.'}
$folder=Join-Path $env:ProgramFiles 'ClevoEntertainmentBootTest'
if(Test-Path -LiteralPath $folder){throw 'Destination exists. Existing installation left unchanged.'}
Write-Host 'Experimental hardware request at every full boot, including battery power. Saved mode is NOT changed.' -ForegroundColor Yellow
if((Read-Host 'Type YES to install') -cne 'YES'){Write-Host 'Cancelled.';return}
New-Item -ItemType Directory -Path $folder|Out-Null
$acl=New-Object Security.AccessControl.DirectorySecurity
$acl.SetAccessRuleProtection($true,$false)
foreach($s in @('S-1-5-18','S-1-5-32-544')){
 $sid=New-Object Security.Principal.SecurityIdentifier($s)
 $rule=New-Object Security.AccessControl.FileSystemAccessRule($sid,'FullControl','ContainerInherit,ObjectInherit','None','Allow')
 $acl.AddAccessRule($rule)
}
$sid=New-Object Security.Principal.SecurityIdentifier('S-1-5-32-545')
$rule=New-Object Security.AccessControl.FileSystemAccessRule($sid,'ReadAndExecute','ContainerInherit,ObjectInherit','None','Allow')
$acl.AddAccessRule($rule)
Set-Acl -LiteralPath $folder -AclObject $acl
$target=Join-Path $folder 'ClevoEntertainmentBootV2.exe'
Copy-Item -LiteralPath $source -Destination $target
if((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash -ne $hash){throw 'Installed EXE hash mismatch; task not registered.'}
& $target --self-test
if($LASTEXITCODE -ne 0){throw 'Hardware-free self test failed; task not registered.'}
$action=New-ScheduledTaskAction -Execute $target -WorkingDirectory $folder
$trigger=New-ScheduledTaskTrigger -AtStartup
$principal=New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
$settings=New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Minutes 1) -Priority 4
Register-ScheduledTask -TaskName $name -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description 'Experimental OEM entertainment request before FnKey; tested only on one COLORFIRE MEOW R16 24H. No thermal protection changes.'|Out-Null
Write-Host 'Installed. No hardware request executed during installation. Restart Windows to test.'
Write-Host ('Log: '+(Join-Path $folder 'boot-v2.log'))
