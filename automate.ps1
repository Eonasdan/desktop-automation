param (
    [Parameter(Mandatory=$true)][string] $url,
    [switch] $install,
    [switch] $uninstall
)

Add-Type -AssemblyName System.Net.Http
#Clear-Host

$httpClient = New-Object System.Net.Http.HttpClient

function Get-Stream{
    param(
		[Parameter()]
		[string] $fetch
	)

    Write-Host "Downloading install file"    
    $response = $httpClient.GetAsync($fetch)
    $response.Wait()

    $sr = New-Object System.IO.StreamReader($response.Result.Content.ReadAsStreamAsync().Result)

    return $sr
}

if ($install) {
    $installStream = (Get-Stream "$url/install.txt")
    while (-not $installStream.EndOfStream){
        $app = $installStream.ReadLine()
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
        Write-host "Uninstalling:" $app
        Get-AppxPackage -allusers $app | Remove-AppxPackage
    }
    }
    else {
        Write-Output "Uninstall requires elevated permissions. Run the script as an admin"
    }
}
