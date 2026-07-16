<powershell>
# --- Ansible WinRM bootstrap (runs at first boot as SYSTEM) ---
$UserName = "ansible"
$Password = "ThomsonReuters@1711"

# 1. Create the local admin user
$sec = ConvertTo-SecureString $Password -AsPlainText -Force
if (Get-LocalUser -Name $UserName -ErrorAction SilentlyContinue) {
    Set-LocalUser -Name $UserName -Password $sec
} else {
    New-LocalUser -Name $UserName -Password $sec -PasswordNeverExpires -AccountNeverExpires
}
Add-LocalGroupMember -Group "Administrators" -Member $UserName -ErrorAction SilentlyContinue

# 2. Enable WinRM / PowerShell Remoting
Set-Service -Name WinRM -StartupType Automatic
Enable-PSRemoting -Force -SkipNetworkProfileCheck

# 3. HTTPS listener with a self-signed cert (port 5986)
$existing = Get-ChildItem WSMan:\localhost\Listener -Force |
    Where-Object { $_.Keys -contains "Transport=HTTPS" }
if (-not $existing) {
    $cert = New-SelfSignedCertificate -DnsName $env:COMPUTERNAME -CertStoreLocation Cert:\LocalMachine\My
    New-WSManInstance -ResourceURI winrm/config/Listener `
        -SelectorSet @{Address="*"; Transport="HTTPS"} `
        -ValueSet @{Hostname=$env:COMPUTERNAME; CertificateThumbprint=$cert.Thumbprint}
}

# 4. Auth + allow local-account remote access
Set-Item -Path WSMan:\localhost\Service\Auth\Negotiate -Value $true -Force
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' `
    -Name LocalAccountTokenFilterPolicy -Value 1 -Type DWord -Force

# 5. Firewall rule for 5986
New-NetFirewallRule -DisplayName "WinRM HTTPS" -Direction Inbound `
    -Protocol TCP -LocalPort 5986 -Action Allow -ErrorAction SilentlyContinue
</powershell>
<persist>true</persist>
