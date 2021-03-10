# Powershell Module Scaffolder

## Depends on powershell 5.1 (the default windows powershell on most systems)

## Cloning
Clone this repository into a modules path.


Check the list of potential module path folders with:
> $env:PSModulePath -replace ";", "`n" 

I typically store them in the directory that is a distant descendant under my Documents folder

All powershell scripts and modules should be stored in the script and module paths recommended by powershell for most convenience.

## Scaffolding a project/module/script using this module
Check available modules on your PC to see if this project is in the listing:
> Get-Module -ListAvailable -Name powershell_scaffolder

Output of this command should be similar to:

>  Directory: C:\Users\you\OneDrive\Documents\WindowsPowerShell\Modules


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
