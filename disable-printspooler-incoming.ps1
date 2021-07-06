<#
.Synopsis
   Disable 'Allow Print Spooler to accept client connections'.
.DESCRIPTION
   Script to disable client connections to the print spooler as a workaround for CVE-2021-1675.
.EXAMPLE
  Just run and have fun!
.OUTPUTS
  Nothing.
.NOTES
   Author:         Joep Verhaeg
   Creation Date:  July 2021
#>

# Registry Hive	    HKEY_LOCAL_MACHINE
# Registry Path	    Software\Policies\Microsoft\Windows NT\Printers
# Value Name	    RegisterSpoolerRemoteRpcEndPoint
# Value Type	    REG_DWORD
# Enabled Value     1
# Disabled Value    2

$value = 2

if (Test-Path -Path 'HKLM:Software\Policies\Microsoft\Windows NT\Printers') {
    try {
        Get-ItemProperty -Path 'HKLM:Software\Policies\Microsoft\Windows NT\Printers\' | Select-Object -ExpandProperty 'RegisterSpoolerRemoteRpcEndPoint' -ErrorAction Stop | Out-Null
        Set-Itemproperty -Path 'HKLM:Software\Policies\Microsoft\Windows NT\Printers' -Name 'RegisterSpoolerRemoteRpcEndPoint' -value $value
    }
    catch {
        New-ItemProperty -Path 'HKLM:Software\Policies\Microsoft\Windows NT\Printers' -Name "RegisterSpoolerRemoteRpcEndPoint" -Value $value -PropertyType "dword"
    }
}
else {
    New-Item -Path 'HKLM:Software\Policies\Microsoft\Windows NT' -Name 'Printers'
    New-ItemProperty -Path 'HKLM:Software\Policies\Microsoft\Windows NT\Printers' -Name "RegisterSpoolerRemoteRpcEndPoint" -Value $value -PropertyType "dword"
}

# Restart the Print Spooler Service
Restart-Service Spooler -Force


