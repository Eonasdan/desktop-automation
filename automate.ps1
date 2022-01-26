param (
    [Parameter(Mandatory=$true)][string] $url,
    [switch] $install,
    [switch] $uninstall
)

#Install WinGet
#Based on this gist: https://gist.github.com/crutkas/6c2096eae387e544bd05cde246f23901
$hasPackageManager = Get-AppPackage -name 'Microsoft.DesktopAppInstaller'
if (!$hasPackageManager -or [version]$hasPackageManager.Version -lt [version]"1.10.0.0") {
    "Installing winget Dependencies"
    Add-AppxPackage -Path 'https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx'

    $releases_url = 'https://api.github.com/repos/microsoft/winget-cli/releases/latest'

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $releases = Invoke-RestMethod -uri $releases_url
    $latestRelease = $releases.assets | Where-Object { $_.browser_download_url.EndsWith('msixbundle') } | Select-Object -First 1

    "Installing winget from $($latestRelease.browser_download_url)"
    Add-AppxPackage -Path $latestRelease.browser_download_url
}

Add-Type -AssemblyName System.Net.Http
$httpClient = New-Object System.Net.Http.HttpClient

function Get-Stream{
    param(
		[Parameter()]
		[string] $fetch
	)

    $response = $httpClient.GetAsync($fetch)
    $response.Wait()

    $sr = New-Object System.IO.StreamReader($response.Result.Content.ReadAsStreamAsync().Result)

    return $sr
}

if ($install) {
    $installStream = (Get-Stream "$url/install.txt")
    while (-not $installStream.EndOfStream){
        $app = $installStream.ReadLine()
        if ($app -eq "404: Not Found") {
            Write-Host "Installation file not found"
            break
        }
        Write-host "Trying:" $app
        $listApp = winget list --exact -q $app
        if (![String]::Join("", $listApp).Contains($app)) {
            Write-host "Installing:" $app
            winget install --exact --silent $app.name
        }
        else {
            Write-host "Skipping Install of " $app
        }
    }
}

#Remove Apps

if ($uninstall) {
    function Test-Administrator
    {
        $user = [Security.Principal.WindowsIdentity]::GetCurrent();
        (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    }

    if (Test-Administrator) {

    Write-Output "Removing Apps"

        $uninstallStream = (Get-Stream "$url/uninstall.txt")
        while (-not $uninstallStream.EndOfStream){
            $app = $uninstallStream.ReadLine()
            if ($app -eq "404: Not Found") {
                Write-Host "Uninstall file not found"
                break
            }
            Write-host "Uninstalling:" $app
            Get-AppxPackage -allusers $app | Remove-AppxPackage
        }
    }
    else {
        Write-Output "Uninstall requires elevated permissions. Run the script as an admin"
    }
}
