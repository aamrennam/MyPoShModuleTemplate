<#
.DESCRIPTION
    Generic build template file that triggers .\psake.ps1 containing build definitions

.EXAMPLE 
    .\build.ps1

    Triggers the default task(s) in .\psake.ps1

.EXAMPLE
    .\build.ps1 build 

    Triggers the build task(s) in .\psake.ps1
#>
[CmdletBinding()]
param ($Task = 'Default')

# Grab nuget bits, install modules, set build variables, start build.
Get-PackageProvider -Name NuGet -ForceBootstrap | Out-Null

# Install dependant modules for the build process
if (-not (Get-Module -Name Psake -ListAvailable)) {
    Install-Module Psake -Force
}

if (-not (Get-Module -name Pester -ListAvailable)) {
    Install-Module Pester -Force -SkipPublisherCheck
}

if (-not (Get-Module -Name PSScriptAnalyzer -ListAvailable)) {
    Install-Module PSScriptAnalyzer -Force
}

if (-not (Get-Module -Name platyps -ListAvailable)) {
    Install-Module platyps -Force
}

Import-Module Psake
# Invoke build script
Invoke-psake -buildFile $PSScriptRoot\psake.ps1 -taskList $Task -nologo -Verbose:$VerbosePreference
exit ( [int]( -not $psake.build_success ) )