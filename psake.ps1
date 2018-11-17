<#
.SYNOPSIS
    Psake script for analyze, test, build and deploy tasks

.DESCRIPTION
    This script contains psake tasks to automate continuous integration and deployment for a given module.
        
        - It analyzes scripts in the module utilizing PSScriptAnalyser. 
        - It tests any *.Tests.ps1 files using Pester.
        - It will build and package the module to a compressed file.
        - It deploys to an Azure Automation account with AzureRm.Automation

.EXAMPLE
    Running the script without parameters only triggers the Analyze and Test tasks.

    PS C:\Module\build.ps1 
    Executing Analyze
    Executing Test

    psake succeeded executing C:\Module\psake.ps1

    ----------------------------------------------------------------------
    Build Time Report
    ----------------------------------------------------------------------
    Name    Duration
    ----    --------
    Analyze 00:00:00.020
    Test    00:00:00.005
    Total:  00:00:00.086

.EXAMPLE 
    Running the script with 'Build' parameter triggers the build task and other dependant tasks.
    This will copy the module to a separate Release folder, generate the Module Manifest file and compress the
    module to the Release folder.
    
    PS C:\Module>.\build.ps1 Build
    Executing Analyze
    Executing Test
    Executing all tests in 'C:\Module\Tests\Get-Information.Tests.ps1'

    Executing script C:\Module\Tests\Get-Information.Tests.ps1

        Describing Get-Information
            [+] Tests something in the code 48ms
    Tests completed in 48ms
    Tests Passed: 1, Failed: 0, Skipped: 0, Pending: 0, Inconclusive: 0
    Executing Clean
    Executing BuildModule
    Executing BuildDocs
    Executing build

    psake succeeded executing C:\Module\psake.ps1

    ----------------------------------------------------------------------
    Build Time Report
    ----------------------------------------------------------------------
    Name        Duration
    ----        --------
    Analyze     00:00:00.013
    Test        00:00:00.149
    Clean       00:00:00.009
    BuildModule 00:00:00.037
    BuildDocs   00:00:00.217
    Build       00:00:00.001
    Total:      00:00:00.433
    
#>

Properties {
    # Edit me if different module name
    $ModuleName = 'MyPoShModuleTemplate'

    # Edit me for documentation
    $HelpVersion = '0.0.1'
    $FwLink = 'https://github.com/aamrennam/MyPoShModuleTemplate'
    $HelpLocale = "en-US" # More agnostic approach: (Get-Culture).Name

    # Source 
    $ModulePath = Join-Path -Path $PSScriptRoot -ChildPath 'src'
    $ManifestTemplate = Join-Path -Path $ModulePath -ChildPath "$ModuleName.psd1"
    $Version = (Import-PowerShellDataFile -Path $ManifestTemplate).ModuleVersion
    
    # Build 
    $OutputDir = Join-Path -Path $PSScriptRoot -ChildPath "release"
    $ModuleOutputDir = Join-Path -Path $OutputDir -ChildPath "$ModuleName\$Version"
    $ManifestPath = Join-Path -Path $ModuleOutputDir -ChildPath "$ModuleName.psd1"
    $ReleaseFile = Join-Path -Path $OutputDir -ChildPath "$ModuleName.zip"

    # Documentation
    $DocsDir = Join-Path -Path $PSScriptRoot -ChildPath docs
}

Task default -depends Analyze, Test

# Analyze the scripts with PSScriptAnalyser
Task Analyze {
    foreach ($script in (Get-ChildItem $ModulePath -Include *.ps1 -Exclude *.Tests.ps1 -Recurse)) {
        $saResults = Invoke-ScriptAnalyzer -Path $script -Severity @('Error', 'Warning') -Recurse -Verbose:$false
        if ($saResults) {
            $saResults | Format-Table  
            Write-Error -Message 'One or more Script Analyzer errors/warnings where found. Build cannot continue!'        
        }
    }
}

# Run tests with Pester
Task Test {
    ForEach ($TestScript in (Get-ChildItem -Path $PSScriptRoot\Tests -Filter *.Tests.ps1)) {
        $TestResults = Invoke-Pester -Path $TestScript.FullName -PassThru
        if ($TestResults.FailedCount -gt 0) {
            $TestResults | Format-List
            Write-Error -Message 'One or more Pester tests failed. Build cannot continue!'
        }
    }
}

# Clean output directory
Task Clean {
    if (Test-Path -Path $OutputDir) {
        Remove-Item -Path $OutputDir -Recurse -Force
    }
}

# Build the module
Task BuildModule -depends Analyze, Test, Clean {
    if (-not (Test-Path $ModuleOutputDir)) {
        $null = New-Item -Path $ModuleOutputDir -ItemType Directory 
    }

    Copy-Item -Path (Join-Path -Path $ModulePath -ChildPath *) -Destination $ModuleOutputDir -Recurse
    $ManifestParams = Import-PowerShellDataFile $ManifestTemplate
    New-ModuleManifest -Path $ManifestPath @ManifestParams
    
    # Compress output directory 
    Compress-Archive -Path $ModuleOutputDir -DestinationPath $ReleaseFile 
}

# Build the documentation for the module 
Task BuildDocs -depends BuildModule {
    if (-not (Test-Path $DocsDir)) {
        $null = New-Item -Path $DocsDir -ItemType Directory
    }
    # Import module with global parameter, else platyps fails
    Import-Module -Name $OutputDir\$ModuleName -Global
    $HelpParams = @{
        Module         = $ModuleName
        OutputFolder   = $DocsDir
        WithModulePage = $true
        FwLink         = $Fwlink
        HelpVersion    = $HelpVersion
    }
    # Create markdown help
    # TODO! Implement Update-MarkdownHelp for existing docs.
    $null = New-MarkdownHelp @HelpParams -Force 

    # Create external help
    $ExternalHelp = Join-Path -Path $ModuleOutputDir -ChildPath $HelpLocale 
    if (-not (Test-Path $ExternalHelp)) {
        $null = New-Item -Path $ExternalHelp -ItemType Directory 
    }
    $null = New-ExternalHelp -Path $DocsDir -OutputPath $ExternalHelp -Force
}

Task Build -depends BuildDocs {
    Remove-Module -Name $ModuleName 
    # Additional build tasks here
}