$env:path = "$pwd;$env:path"

# nssm url
$nssm_url='https://nssm.cc/release/nssm-2.24.zip'

# eg 2.24
$nssm_version = $nssm_url -replace '\D+-([\d\.]+).zip.*','$1'

# eg nssm-2.24
$installer_basename = $nssm_url -replace '.*/(.*?).zip$','$1'

# eg nssm-2.24.zip
$nssm_zip = $nssm_url -replace '.*/(.*?.zip)$','$1'

<#
$nssm_url
$nssm_version
$installer_basename
$nssm_zip
#>

$cdir = (Get-Location).Path

if(!(test-path "$cdir\7za.exe"))
{
    (new-object System.Net.WebClient).DownloadFile("http://installer-bin.streambox.com/7za.exe", "7za.exe")
}

if(!(test-path "$cdir\nssm.exe"))
{
    (new-object System.Net.WebClient).DownloadFile("$nssm_url", "$nssm_zip")
    & 7za x -y $nssm_zip >7za_out.txt
    Copy ((Get-Location).Path + "\" + "$installer_basename\win32\nssm.exe") .
}
