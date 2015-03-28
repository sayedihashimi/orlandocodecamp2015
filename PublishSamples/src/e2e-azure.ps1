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

<#
function BuildAndBundle{
    [cmdletbinding()]
    param(
        $rootSrcdir,
        $name,
        $packOutdir
    )
    begin{ Push-Location }
    end{ Pop-Location }
    process{
        $srcDir = (get-item (join-path $rootSrcdir $name)).FullName
        Set-Location $srcDir
'*********************************************
build and bundle [{0}]
*********************************************' -f $srcDir | Write-Output
'***** restoring nuget packages ****' | Write-Output
        kpm restore

'**** building project ****' | Write-Output
        kpm build

'**** bundling to [{0}] ****' -f $outdir | Write-Output
        $outdir = (new-item (join-path $packOutDir $name) -ItemType Directory).FullName
        kpm @('bundle', '-o', "$outdir")
        Set-Location $outdir
    }
}

BuildAndBundle -rootSrcdir $sourceRoot -name 'WebApp01' -packOutdir $packOutDir

# now publish to azure with the existing script
$publishScript
#>
'Publishing to Azure' | Write-Output
& 'C:\Data\personal\mycode\orlandocc-2015\PublishSamples\src\PubSamples\Properties\PublishProfiles\AzureSayed-publish.ps1' -packOutput $packOutDir -publishProperties @{
     'WebPublishMethod'='MSDeploy'
     'MSDeployServiceURL'='sayed01.scm.azurewebsites.net:443';
     'DeployIisAppPath'='sayed01';'Username'='$sayed01';'Password'="$publishPwd"
}

