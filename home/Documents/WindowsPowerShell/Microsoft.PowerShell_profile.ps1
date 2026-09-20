# Windows PowerShell 5.1 profile.
#
# Windows PowerShell (powershell.exe) and PowerShell 7 (pwsh.exe) don't share
# a profile path, so this just dot-sources the canonical one instead of
# duplicating it.
. (Join-Path $PSScriptRoot '..\PowerShell\Microsoft.PowerShell_profile.ps1')
