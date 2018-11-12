## About

This repository contains a templated PowerShell module to simplify creation of new modules.

## Overview

This repository contains a templated PowerShell module to simplify creation of new modules.

## Usage

A ```psake``` script has been created to manage the various operations related to testing and building of ```MyPoShModuleTemplate```. 

### Build Operations


* Test the script via Pester and Script Analyzer  
```powershell

.\build.ps1
```
    
* Build the code and documentation
```powershell

.\build.ps1 -Task Build
```