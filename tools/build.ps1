<#
  构建 TrafficMonitor（含本补丁）x64 Release。
  用法示例：
    powershell -File tools\build.ps1 `
      -RepoRoot D:\src\TrafficMonitor `
      -MSBuild 'C:\Program Files\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin\MSBuild.exe'
  可选：
    -TargetFrameworkRootPath <path>   # C++/CLI 工程找不到 .NET 4.7.2 引用程序集时，指向解压后的 net472 引用程序集（...\build 目录）
#>
param(
  [Parameter(Mandatory=$true)][string]$RepoRoot,
  [Parameter(Mandatory=$true)][string]$MSBuild,
  [string]$TargetFrameworkRootPath = ''
)
$ErrorActionPreference = 'Stop'
$props = Join-Path $PSScriptRoot 'utf8.props'
$sln = Join-Path $RepoRoot 'TrafficMonitor.sln'
$argsList = @($sln, '/m', '/nologo', '/v:m', '/p:Configuration=Release', '/p:Platform=x64',
  '/p:ExternalCompilerOptions=/utf-8', "/p:ForceImportBeforeCppTargets=$props")
if ($TargetFrameworkRootPath) { $argsList += "/p:TargetFrameworkRootPath=$TargetFrameworkRootPath" }
& $MSBuild @argsList
Write-Output ('MSBUILD_EXIT=' + $LASTEXITCODE)
