# once
# Import-Module ServerManager
# Add-WindowsFeature Web-Scripting-Tools

Clear-Host
Import-Module WebAdministration

# erwgdgfhnfghn
function copyDeployedFiles {
    param (
        $currentSitePath,
        $currentSiteFolder,
        $newSiteFolder,
        $deployPath 
    )
    
    # get root site path
    $newRootPath = ""
    $newRoot = $currentSitePath | ForEach-Object {$_ -replace $currentSiteFolder , $newSiteFolder} 
    $array = $newRoot.Split("\")
    foreach ( $value in $array ) {
        if ( $value -eq $array[-1] ) { break }
        $newRootPath += "$value" + '\'
    }

    # Remove old site files
    Get-ChildItem -Path $newRootPath -Recurse | Remove-Item -force -Recurse

    # copy files
    Copy-Item -Path "$deployPath\*" -Destination $newRootPath -Force -Recurse -Exclude "*.ps1"
}

function rewriteApplicationPath {
    param (
        $siteApps,
        $currentSiteFolder,
        $newSiteFolder,
        $langs,
        $site
    )

    foreach ( $app  in $siteApps ) {
        $path = $app.path
        $appName = $path.TrimStart("/")

        # check applications 
        if ( $appName -notin $langs ) { continue }
        
        # new site path
        $newAppPath = $app.PhysicalPath | ForEach-Object {$_ -replace $currentSiteFolder, $newSiteFolder}
        
        # copy old folder, if not deployed 
        if ( ! (Test-Path $newAppPath) ) {
            copy-item -Path $app.PhysicalPath -Destination $newAppPath -Recurse 
        }
        
        # rewrite new application site path
        $iisSite = "IIS:\Sites\$site\$appName"
    
        Set-ItemProperty $iisSite -Name physicalPath -Value $newAppPath
    }
}


function rewriteRootSitePath {
    param (
        $currentSitePath,
        $currentSiteFolder,
        $newSiteFolder,
        $site
    )
    # get root site path
    $newRootSitePath = $currentSitePath | ForEach-Object {$_ -replace $currentSiteFolder, $newSiteFolder}

    # check root folder in new (deployed) folder
    if ( ! (Test-Path $newRootSitePath) ) { copy-item -Path $currentSitePath -Destination $newRootSitePath -Recurse }

    # rewrite new root site path
    Set-ItemProperty "IIS:\Sites\$site" -Name physicalPath -Value $newRootSitePath
}


# === main ===
$site = "test.onlyoffice.co"
$deployPath = "D:\test.onlyoffice.co\deploy"
$langs = @('fr','ru')

$siteApps = Get-WebApplication -Site $site
$siteRoot = Get-Childitem -path IIS:\Sites | Where-Object {$_.name -like "$site"}
$currentSitePath = $siteRoot.PhysicalPath

write-host "Current site path: $currentSitePath"

# switch site folder
if ( $currentSitePath -like "*onesite*" ) { $newSiteFolder = "twosite" ; $currentSiteFolder = "onesite"}
else { 
    $current = $currentSitePath.Split("\")
    $currentSiteFolder = $current[-2] 
    $newSiteFolder = "onesite"
}

# copy deployed files to site folder
copyDeployedFiles $currentSitePath $currentSiteFolder $newSiteFolder $deployPath 

# rewrite application path
rewriteApplicationPath $siteApps $currentSiteFolder $newSiteFolder $langs $site

# rewrite siteRoot path
rewriteRootSitePath $currentSitePath $currentSiteFolder $newSiteFolder $site

exit

