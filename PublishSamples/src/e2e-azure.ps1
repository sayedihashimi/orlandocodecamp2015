[cmdletbinding()]
param(
    [string]$sourceRoot,
    [string]$pubTempDir,
    [string]$packOutDir,
    [string]$publishPwd = $env:AzureSayedPublishPwd
)

function Get-ScriptDirectory
{
    $Invocation = (Get-Variable MyInvocation -Scope 1).Value
    Split-Path $Invocation.MyCommand.Path
}
$scriptDir = ((Get-ScriptDirectory) + "\")

if(!$sourceRoot){ $sourceRoot = $scriptDir }
if(!$pubTempDir){ $pubTempDir = (Join-Path $env:temp 'sayed\e2e\publish\pubtemp') }
if(!$packOutDir){ $packOutDir = (Join-Path $pubTempDir 'packout') }
if(!$publishPwd){ throw ('Publish password missing') }
if(!(Test-Path $sourceRoot)){ throw ('Source root not found at: [{0}]' -f $sourceRoot) }

if(Test-Path $pubTempDir){ Remove-Item $pubTempDir -Recurse -Force }
if(Test-Path $packOutDir){ Remove-Item $packOutDir -Recurse -Force }

New-Item $pubTempDir -ItemType Directory
New-Item $packOutDir -ItemType Directory

$packOutDir = (Get-Item $packOutDir).FullName

try{
    Push-Location
    $srcDir = (get-item (join-path $sourceRoot 'WebApp01')).FullName
    Set-Location $srcDir

    kpm restore
    kpm build

    kpm @('bundle', '-o', "$packOutDir")
    Set-Location $packOutDir
}
finally{
    Pop-Location
}

'Publishing to Azure' | Write-Output
$pubscript = (get-item (Join-Path $sourceRoot 'PubSamples\Properties\PublishProfiles\AzureSayed-publish.ps1')).FullName
&($pubscript) -packOutput $packOutDir -publishProperties @{
     'WebPublishMethod'='MSDeploy'
     'MSDeployServiceURL'='sayed01.scm.azurewebsites.net:443';
     'DeployIisAppPath'='sayed01';'Username'='$sayed01';'Password'="$publishPwd"
}