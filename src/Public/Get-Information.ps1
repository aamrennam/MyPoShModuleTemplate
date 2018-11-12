<#
.SYNOPSIS
    Sample script for template

.DESCRIPTION
    This is just a simple script to generate documentation with platyps
    as part of the build process with psake.
    The script will either print processes or services.

.PARAMETER Process
    Switch to show process 
    
.EXAMPLE 
    Get-Information

    Status   Name               DisplayName
    ------   ----               -----------
    Running  AdobeARMservice    Adobe Acrobat Update Service
    Running  AESMService        Intel® SGX AESM
    Stopped  AJRouter           AllJoyn Router Service
    Stopped  ALG                Application Layer Gateway Service
    Stopped  AppIDSvc           Application Identity
    
.EXAMPLE 
    Get-Information -Process

    NPM(K)    PM(M)      WS(M)     CPU(s)      Id  SI ProcessName
    ------    -----      -----     ------      --  -- -----------
      9     1,96       7,35       0,00    1220   0 aesm_service
     31    26,81      33,60       8,75   15972   1 ApplicationFrameHost
     11     2,88       6,21       0,00    4532   0 armsvc
     26    14,90      35,14       0,31   15772   1 Calculator
     11     2,49       0,82       6,75   12044   1 CAudioFilterAgent64
    
.NOTES 
    Author: jon@rynning.no

#>

Function Get-Information {
    # Add HelpUri to support -Online parameter with Get-Help
    [CmdletBinding(HelpUri="http://shortUriNameSvc.ly/Get-Information")]
    [OutputType("ServiceController")]
    [OutputType([System.Diagnostics.Process], ParameterSetName = "Process")]
    Param (
        [Parameter(ParameterSetName = "Process")]
        [switch]$Process
    )
    
    if ($Process) {
        Get-Process
    }
    else {
        Get-Service
    }
}
