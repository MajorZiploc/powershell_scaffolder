# Powershell Module Scaffolder

## Compatible with powershell core and powershell 5.1 (the default windows powershell on most systems)

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

To create a powershell script:
> Initialize-Script

Follow the prompts that this commands asks you, and you will have your powershell module/project/script scaffolded!

## Development Tools
- VSCode
- Powershell extension for vscode

