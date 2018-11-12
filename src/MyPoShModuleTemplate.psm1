# Only edit this file if you know what you are doing.

Write-Verbose -Message "Importing Functions"
# Import everything in these folders
foreach ($Folder in @('Private', 'Public')) {
    # Get the module root
    $ModuleRoot = Join-Path -Path $PSScriptRoot -ChildPath $Folder
    if (Test-Path -Path $ModuleRoot) {
        Write-Verbose -Message "Processing folder $ModuleRoot"
        $Files = Get-ChildItem -Path $ModuleRoot -Filter *.ps1

        # dot source each file
        $Files | where-Object { $_.Name -NotLike '*.Tests.ps1'} | 
            ForEach-Object {
                Write-Verbose -Message "Importing $($_.Name)"
                . $_.FullName
            }
    }
}

# Export public script files
Export-ModuleMember -Function (Get-ChildItem -Path "$PSScriptRoot\public\*.ps1").basename