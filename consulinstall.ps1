function open_firewall()
{
    # firewall
    & netsh advfirewall firewall delete rule name="Consul HashiCorp UDP" protocol=UDP localport="8300,8301,8302,8400,8500,8600" | out-null
    & netsh advfirewall firewall delete rule name="Consul HashiCorp TCP" protocol=TCP localport="8300,8301,8302,8400,8500,8600" | out-null

    # allow binary
    ##############################
    & netsh advfirewall firewall delete rule name="Consul HashiCorp App" program="C:\ProgramData\consul\consul.exe" | out-null
    & netsh advfirewall firewall add rule name="Consul HashiCorp App" dir=in action=allow program="C:\ProgramData\consul\consul.exe" enable=yes | out-null

    ##############################

    # tcp/8300 for RPC
    & netsh advfirewall firewall delete rule name="Consul HashiCorp RPC" dir=in protocol=TCP localport=8300 | out-null
    & netsh advfirewall firewall add rule name="Consul HashiCorp RPC" dir=in action=allow protocol=TCP localport=8300 | out-file install.log

    ##############################

    # Serf LAN (Default 8301). This is used to handle gossip in the
    # LAN. Required by all agents. TCP and UDP.

    # TCP/8301 for Serf LAN
    & netsh advfirewall firewall delete rule name="Consul HashiCorp Serf LAN (TCP)" dir=in protocol=TCP localport=8301 | out-null
    & netsh advfirewall firewall add rule name="Consul HashiCorp Serf LAN (TCP)" dir=in action=allow protocol=TCP localport=8301 | out-file install.log

    # UDP/8301 for Serf LAN
    & netsh advfirewall firewall delete rule name="Consul HashiCorp Serf LAN (UDP)" dir=in protocol=UDP localport=8301 | out-null
    & netsh advfirewall firewall add rule name="Consul HashiCorp Serf LAN (UDP)" dir=in action=allow protocol=UDP localport=8301 | out-file install.log

    ##############################

    # Serf WAN (Default 8400). This is used to handle gossip in the
    # WAN. Required by all agents. TCP and UDP.

    # TCP/8400 for Serf WAN
    & netsh advfirewall firewall delete rule name="Consul HashiCorp Serf WAN (TCP)" dir=in protocol=TCP localport=8400 | out-null
    & netsh advfirewall firewall add rule name="Consul HashiCorp Serf WAN (TCP)" dir=in action=allow protocol=TCP localport=8400 | out-file install.log

    # UDP/8400 for Serf WAN
    & netsh advfirewall firewall delete rule name="Consul HashiCorp Serf WAN (UDP)" dir=in protocol=UDP localport=8400 | out-null
    & netsh advfirewall firewall add rule name="Consul HashiCorp Serf WAN (UDP)" dir=in action=allow protocol=UDP localport=8400 | out-file install.log

    ##############################

    # HTTP API (Default 8500). This is used by clients to talk to the HTTP
    # API. TCP only.

    # TCP/8500 for HTTP API
    & netsh advfirewall firewall delete rule name="Consul HashiCorp HTTP API" dir=in protocol=TCP localport=8500 | out-null
    & netsh advfirewall firewall add rule name="Consul HashiCorp HTTP API" dir=in action=allow protocol=TCP localport=8500 | out-file install.log

    ##############################

    # DNS Interface (Default 8600). Used to resolve DNS queries. TCP and
    # UDP.

    # TCP/8600 DNS
    & netsh advfirewall firewall delete rule name="Consul HashiCorp DNS queries" dir=in protocol=TCP localport=8600 | out-null
    & netsh advfirewall firewall add rule name="Consul HashiCorp DNS queries" dir=in action=allow protocol=TCP localport=8600 | out-file install.log
}

$env:path = "$pwd;$env:path"

$consul_url='https://releases.hashicorp.com/consul/0.5.2/consul_0.5.2_windows_386.zip'
$consul_www_url='https://releases.hashicorp.com/consul/0.5.2/consul_0.5.2_web_ui.zip'
$consul_config_url='https://raw.githubusercontent.com/TaylorMonacelli/consul-install-windows/wip/config.hcl'


# eg 0.5.2
$consul_version = $consul_url -replace '\D+/([\d\.]+)/.*','$1'

# eg consul_0.5.2_windows_386
$installer_basename = $consul_url -replace '.*/(.*?).zip$','$1'

# eg consul_0.5.2_windows_386.zip
$consul_zip = $consul_url -replace '.*/(.*?.zip)$','$1'

# eg consul_0.5.2_web_ui.zip
$consul_www_zip = $consul_www_url -replace '.*/(.*?.zip)$','$1'
$consul_www_zip_basename = $consul_www_zip -replace '.zip',''

$odir = (Get-Location).Path
$cdir = (Get-Location).Path

if(!(test-path "$cdir\$consul_zip"))
{
    (new-object System.Net.WebClient).DownloadFile($consul_url, $consul_zip)
}

if(!(test-path "$cdir\$consul_www_zip"))
{
    (new-object System.Net.WebClient).DownloadFile($consul_www_url, $consul_www_zip)
}

if(!(test-path "$cdir\7za.exe"))
{
    (new-object System.Net.WebClient).DownloadFile("http://installer-bin.streambox.com/7za.exe", "7za.exe")
}
$env:path = "$pwd;$env:path"

# Overwrite config
(new-object System.Net.WebClient).DownloadFile($consul_config_url, "config.hcl")

& 7za x -y $consul_zip | out-null

& 7za x -y -ocweb $consul_www_zip | out-null




$services = @(Get-Service Consul -ErrorAction SilentlyContinue)
foreach ($service in $services)
{
    if ($service.Status -eq 'Running')
    {
        $service | Stop-Service
    }
    & nssm remove Consul confirm | out-file install.log
}

$consul = Get-Process Consul -ErrorAction SilentlyContinue
if ($consul)
{
    $consul | Stop-Process -Force | out-null
}
Remove-Variable consul





if(test-path C:\ProgramData\consul\data){
	Remove-Item -Recurse -Force C:\ProgramData\consul\data
}
$result = new-item -ItemType Directory -Force -Path C:\ProgramData\consul\data
$result = new-item -ItemType Directory -Force -Path C:\ProgramData\consul\config
$result = new-item -ItemType Directory -Force -Path C:\ProgramData\consul\logs
$result = new-item -ItemType Directory -Force -Path C:\ProgramData\consul\www

set-location C:\ProgramData\consul

Get-Process | Where-Object {$_.Path -like "C:\ProgramData\consul\nssm.exe"} | Stop-Process
Copy-Item "$odir\nssm.exe" C:\ProgramData\consul
Copy-Item "$odir\consul.exe" C:\ProgramData\consul
Copy-Item "$odir\config.hcl" C:\ProgramData\consul\config
Copy-Item -Force -Recurse "$odir\cweb\dist\*" C:\ProgramData\consul\www

$ws = New-Object -comObject WScript.Shell
$Dt = $ws.SpecialFolders.item("Desktop")
$URL = $ws.CreateShortcut($Dt + "\Consul.url")
$URL.TargetPath = "http://localhost:8500/ui"
$URL.Save()

set-location C:\ProgramData\consul

# Ensure that the nssm.exe we're calling is the one from
# C:\ProgramData\consul
$env:path = "C:\ProgramData\consul;$env:path"

& nssm install Consul C:\ProgramData\consul\consul.exe confirm | out-file install.log
& nssm set Consul AppDirectory C:\ProgramData\consul | out-file install.log
& nssm set Consul AppParameters agent -server -config-file C:\ProgramData\consul\config\config.hcl | out-file install.log
& nssm set Consul DisplayName Consul | out-file install.log
& nssm set Consul Description Consul from HashiCorp | out-file install.log
& nssm set Consul Start SERVICE_AUTO_START | out-file install.log
open_firewall


if(test-path "$env:windir\system32\consul.exe")
{
    remove-item $env:windir\system32\consul.exe -Force
}

& cmd /c mklink $env:windir\system32\consul.exe C:\ProgramData\consul\consul.exe | out-file install.org

& nssm start Consul | out-file install.log
