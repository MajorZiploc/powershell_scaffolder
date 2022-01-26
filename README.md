# Powershell Module Scaffolder

## Compatible with powershell core (pwsh) and powershell 5.1 (powershell) (the default windows powershell on most systems)

## Purpose
A utility library for quickly creating more robust powershell scripts or modules quickly.

## Install

> Install-Module -Name powershell_scaffolder -Scope CurrentUser -Force

## Scaffolding a project/module/script using this module
Check available modules on your PC to see if this project is in the listing:

> Get-Module -ListAvailable -Name powershell_scaffolder

Output of this command should be similar to:

>  Directory: C:\Users\you\Documents\WindowsPowerShell\Modules


` ModuleType Version    Name                                ExportedCommands `

` Script     1.0        powershell_scaffolder                          (Initialize-Module,Initialize-Script) `

If you see this output, it means you can import this module into your current powershell session with:
>  Import-Module -Name powershell_scaffolder

Now you can call the exported commands from this module in your powershell terminal:
To create a powershell module or project:
> Initialize-Module

Or you can provide all arguments so that you do not get a prompt (non powershell type shells require this route):
> pwsh -Command '& {Set-StrictMode -Version 3; Import-Module powershell_scaffolder; Initialize-Module -Path ./ -ModuleName "test_module" -Author "You!" -Description "Test powershell module" -ModuleVersion "0.0.1" -PowershellVersion "7.0" -CompanyName "N/A" -CopyRight "N/A";}'

To create a powershell script:
> Initialize-Script

Or you can provide all arguments so that you do not get a prompt (non powershell type shells require this route):
> pwsh -Command '& {Set-StrictMode -Version 3; Import-Module powershell_scaffolder; Initialize-Script -Path ./ -ScriptName "test_script" -ShouldUseAdvLogging }'

Follow the prompts that this commands asks you, and you will have your powershell module/project/script scaffolded!

## Development Tools
- vscode
  - ms-vscode.powershell
- just (command runner) v0.10.0

