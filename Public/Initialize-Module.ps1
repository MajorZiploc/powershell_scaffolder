. "$PSScriptRoot/../Private/Shared-Res.ps1"

function Initialize-Module {
  param(
    [Parameter(Mandatory = $false)]
    [string]
    $Path = (Read-Host -Prompt "Root path where project should be scaffolded (./): "),
    [Parameter(Mandatory = $true,HelpMessage = "May only be made up of numbers, letters, and some special characters. Regex that passes: ^[\w\d._-]+$")]
    [string]
    [ValidatePattern("^[\w\d._-]+$")]
    $ModuleName,
    [Parameter(Mandatory = $false)]
    [string]
    $Author = (Read-Host -Prompt "Author of Project (N/A): "),
    [Parameter(Mandatory = $false)]
    [string]
    $Description = (Read-Host -Prompt "Project Description (N/A): "),
    [Parameter(Mandatory = $false)]
    [string]
    $PowershellVersion = (Read-Host -Prompt "Powershell Version (5.1): "),
    [Parameter(Mandatory = $false)]
    [string]
    $ModuleVersion = (Read-Host -Prompt "Starting version of this project (0.1): "),
    [Parameter(Mandatory = $false)]
    [string]
    $CompanyName = (Read-Host -Prompt "Company name (N/A): "),
    [Parameter(Mandatory = $false)]
    [string]
    $CopyRight = (Read-Host -Prompt "Copy right (N/A): ")
  )
  function Invoke-Scaffold {
    [CmdletBinding()]
    param()
    process {
      try {
        # $pv = [System.Version]::Parse($PowershellVersion)
        # $mv = [System.Version]::Parse($ModuleVersion)
        if (($null -eq $Path) -or '' -eq $Path) {
          $Path = "./"
        }
        if (($null -eq $Author) -or '' -eq $Author) {
          $Author = "N/A"
        }
        if (($null -eq $Description) -or '' -eq $Description) {
          $Description = "N/A"
        }
        if (($null -eq $PowershellVersion) -or '' -eq $PowershellVersion) {
          $PowershellVersion = "5.1"
        }
        if (($null -eq $ModuleVersion) -or '' -eq $ModuleVersion) {
          $ModuleVersion = "0.1"
        }
        if (($null -eq $CompanyName) -or '' -eq $CompanyName) {
          $CompanyName = "N/A"
        }
        if (($null -eq $CopyRight) -or '' -eq $CopyRight) {
          $CopyRight = "N/A"
        }

        # Create the module and private function directories
        mkdir $Path/$ModuleName
        mkdir $Path/$ModuleName/Private
        mkdir $Path/$ModuleName/Public
        mkdir $Path/$ModuleName/en-US # For about_Help files
        mkdir $Path/$ModuleName/Tests
        mkdir $Path/$ModuleName/settings
        mkdir $Path/$ModuleName/settings/test
        mkdir $Path/$ModuleName/settings/prod

        $appConfigEndPath = "appsettings.json"
        $lastStateEndPath = "lastState.json"
        $appConfig = "$Path/$ModuleName/settings/test/$appConfigEndPath"
        $lastStateConfig = "$Path/$ModuleName/settings/test/$lastStateEndPath"
        $appConfigProd = "$Path/$ModuleName/settings/prod/$appConfigEndPath"
        $lastStateConfigProd = "$Path/$ModuleName/settings/prod/$lastStateEndPath"
        $privateConfigEndPath = "Private/secrets.json"
        $privateConfig = "$Path/$ModuleName/$privateConfigEndPath"
        $blackListedFileName = "BlackListedVariables.txt"

        #Create the module and related files
        New-Item "$Path/$ModuleName/$ModuleName.psm1" -ItemType File
        New-Item "$Path/$ModuleName/$ModuleName.Format.ps1xml" -ItemType File
        New-Item "$Path/$ModuleName/en-US/about_$ModuleName.help.txt" -ItemType File
        New-Item "$Path/$ModuleName/Tests/$ModuleName.Tests.ps1" -ItemType File
        New-Item "$Path/$ModuleName/Private/ErrorHandler.ps1" -ItemType File
        New-Item "$Path/$ModuleName/Private/LogHelper.ps1" -ItemType File
        New-Item "$Path/$ModuleName/Private/Program.ps1" -ItemType File
        New-Item "$Path/$ModuleName/Public/Invoke-$ModuleName.ps1" -ItemType File
        New-Item "$Path/$ModuleName/$blackListedFileName" -ItemType File
        New-Item $appConfig -ItemType File
        New-Item $lastStateConfig -ItemType File
        New-Item $appConfigProd -ItemType File
        New-Item $lastStateConfigProd -ItemType File
        New-Item $privateConfig -ItemType File
        New-Item "$Path/$ModuleName/.gitignore" -ItemType File
        New-ModuleManifest -Path $Path/$ModuleName/$ModuleName.psd1 `
           -RootModule "$ModuleName.psm1" `
           -Description $Description `
           -PowerShellVersion $PowershellVersion `
           -Author $Author `
           -CompanyName $CompanyName `
           -ModuleVersion $ModuleVersion `
           -FunctionsToExport "*" `
           -CmdletsToExport "*" `
           -Copyright $CopyRight
        # -FormatsToProcess "$ModuleName.Format.ps1xml" `

        $moduleString = @'
#Get public and private function definition files.
$Public = @( Get-ChildItem -Path $PSScriptRoot/Public/*.ps1 -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path $PSScriptRoot/Private/*.ps1 -ErrorAction SilentlyContinue )

#Dot source the files
Foreach ($import in @($Public + $Private)) {
    Try {
        . $import.fullname
    }
    Catch {
        Write-Error -Message "Failed to import function $($import.fullname): $_"
    }
}

# Read in or create an initial config file and variable
# Export Public functions ($Public.BaseName) for WIP modules
# Set variables visible to the module and its functions only

Export-ModuleMember -Function $Public.Basename
'@

        $moduleString | Out-File -FilePath "$Path/$ModuleName/$ModuleName.psm1" -Encoding utf8

        $unitTestString = @'
$PSVersion = $PSVersionTable.PSVersion.Major
# import the file with the functions you are testing
# . $PSScriptRoot"/../../Public/Get-Num.ps1"
Describe "<name_of_function1> PS$PSVersion Integrations tests" {
  Context "Strict mode" {
    Set-StrictMode -Version latest
    It "should get valid data" {
      # Simple Mock example
      # Mock Get-PrivateNum {
      #   return 8
      # }
      # Simple assertion
      # $actual = Get-Num -n -10
      # $actual | Should Not Be $null Because "it is always defined."
      # $expected = -2
      # $actual | Should Be $expected Because "the value is 2"
    }
  }
}
# Describe "<name_of_function2> PS$PSVersion Integrations tests" {
#   Context "Strict mode" {
#     Set-StrictMode -Version latest
#     It "should get valid data" {
#     }
#   }
# }
'@

        $unitTestString | Out-File -FilePath "$Path/$ModuleName/Tests/$ModuleName.Tests.ps1" -Encoding utf8

        $logingNotes = Get-LoggingNotes

        $mainFile = @"
$logingNotes
# See the black listed variables file to see what variables to not reassign:
# By default, if you try and reassign a black listed variable, it will throw an error.
#   It is possible to override the value with force, but it is highly recommended not to!
#  $ModuleName/$blackListedFileName

function Program {
  #[CmdletBinding()]
  #param (
    # [Parameter(Mandatory = `$false)]
    # [ValidateRange([int]::MinValue, 0)]
    # [int]
    # `$n = 0
  #)

  # Imports files from same directory as this file
  . `$PSScriptRoot"/LogHelper.ps1"
  . `$PSScriptRoot"/ErrorHandler.ps1"

  return 0
}
"@

        $mainFile | Out-File -FilePath "$Path/$ModuleName/Private/Program.ps1" -Encoding utf8

        $startTimeInfo = Get-StartTimeInfo

        $logCleanupStep = Get-LogCleanupStep

        $runMainFile = @"
# Only edit this file if you intend to write a powershell module or need to use secrets or change the environment
# If you intend to use this as a powershell project, then edit the program file in the private directory

function Invoke-$ModuleName {
  [CmdletBinding()]
  param ()

  # Makes powershell stricter by default to make code safer and more reliable
  Set-StrictMode -Version 3

  # Import statements (follows the bash style dot sourcing notation)
  . `$PSScriptRoot"/../Private/Program.ps1"
  . `$PSScriptRoot"/../Private/ErrorHandler.ps1"
  . `$PSScriptRoot"/../Private/LogHelper.ps1"

  # The environment to use. Determines the app config and state objects to use
  New-Variable -Name environ -Value `$("test") -Option ReadOnly,AllScope -Force
  New-Variable -Name settingsFolder -Value `$("`$PSScriptRoot/../settings") -Option ReadOnly,AllScope -Force
  New-Variable -Name appConfig -Value `$(Get-Content -Path "`$settingsFolder/`$environ/appsettings.json" -Raw | ConvertFrom-Json) -Option ReadOnly,AllScope -Force
  # Secrets object. Things that you do not want to put in git go inside this. Add to the secrets json in the private folder
  # Need to uncomment this line if you want to use secrets. You will likely need to create the file aswell.
  # New-Variable -Name secrets -Value `$(`$PSScriptRoot"/../$privateConfigEndPath") -Option ReadOnly,AllScope -Force

  New-Variable -Name lastStateFilePath -Value `$("`$settingsFolder/`$environ/$lastStateEndPath") -Option ReadOnly,AllScope -Force
  New-Variable -Name lastState -Value `$(Get-Content -Path `$lastStateFilePath -Raw | ConvertFrom-Json) -Option ReadOnly,AllScope -Force

  New-Variable -Name thisScriptName -Value `$(`$MyInvocation.MyCommand.Name -replace ".ps1", "") -Option ReadOnly,AllScope -Force
  New-Variable -Name logFolder -Value `$("`$PSScriptRoot/../logs/`$thisScriptName") -Option ReadOnly,AllScope -Force
  $startTimeInfo
  # Create log directory if it does not exist, does not destroy the folder if it exists already
  New-Item -ItemType Directory -Force -Path "`$logFolder/`$logDate/`$(`$appConfig.runFolderName)" | Out-Null
  New-Item -ItemType Directory -Force -Path "`$logFolder/`$logDate/`$(`$appConfig.summaryFolderName)" | Out-Null

  New-Variable -Name logFile -Value `$("`$logFolder/`$logDate/`$(`$appConfig.runFolderName)/`$(`$appConfig.logFileName)_`$(`$logTime)_log.txt") -Option ReadOnly,AllScope -Force
  New-Variable -Name summaryFile -Value `$("`$logFolder/`$logDate/`$(`$appConfig.summaryFolderName)/`$(`$appConfig.logFileName)_log.txt") -Option ReadOnly,AllScope -Force
  New-Variable -Name keepLogsForNDays -Value `$(`$appConfig.keepLogsForNDays) -Option ReadOnly,AllScope -Force

  `$msg = "Starting process. `$(Get-Date)``n"
  `$msg += "environment: `$environ"
  Write-Txt -txt `$msg
  Write-Json -label "appConfig:" -data `$appConfig
  Write-Json -label "lastState:" -data `$lastState

  try {
    # Program is where you should write your normal powershell script code
    Program -ErrorAction Stop
  }

  catch {
    `$errorDetails = Get-ErrorDetail -error `$_
    Write-Json -label "Top level issue: " -data `$errorDetails
    throw `$_
  }

  finally {
    `$lastState.lastRun = (Get-Date).ToString(`$appConfig.dateFormat)
    `$msg = "Finished process. `$(Get-Date)``n"
    Write-Txt -txt `$msg
    $logCleanupStep
    # update last state json
    `$lastState | ConvertTo-Json | Out-File -FilePath "`$lastStateFilePath" -Encoding utf8
  }
}

# Remove the following line if you are trying to write a powershell module that is importable in other powershell projects/modules
Invoke-$ModuleName -ErrorAction Stop

"@

        $runMainFile | Out-File -FilePath "$Path/$ModuleName/Public/Invoke-$ModuleName.ps1" -Encoding utf8

        $blackListedFileContent = Get-BlackListedVars
        $blackListedFileContent | Out-File -FilePath "$Path/$ModuleName/$blackListedFileName" -Encoding utf8

        $logHelper = Get-LogCleaner
        $logWriter = Get-LogWriter
        $logHelper | Out-File -FilePath "$Path/$ModuleName/Private/LogHelper.ps1" -Encoding utf8
        $logWriter | Out-File -FilePath "$Path/$ModuleName/Private/LogHelper.ps1" -Encoding utf8 -Append

        $errorHandler = Get-ErrorHelperContent
        $errorHandler | Out-File -FilePath "$Path/$ModuleName/Private/ErrorHandler.ps1" -Encoding utf8

        $appJson = @"
{
  "preview": true,
  "keepLogsForNDays": 14,
  "logFileName": "$($ModuleName)",
  "summaryFolderName": "summary",
  "runFolderName": "per_run",
  "dateFormat": "yyyy/MM/dd HH:mm:ss"
}
"@
        $lastStateJson = @"
{
  "state": "Any state from the last run of this program (or last update of this file) that is required for this run.",
  "lastRun": null
}
"@
        $privateConfigJson = @"
{
  "password": "not_put_in_git"
}
"@

        $appJson | Out-File -FilePath "$appConfig" -Encoding utf8
        $lastStateJson | Out-File -FilePath "$lastStateConfig" -Encoding utf8
        $privateConfigJson | Out-File -FilePath "$privateConfig" -Encoding utf8

        $appJson | Out-File -FilePath "$appConfigProd" -Encoding utf8
        $lastStateJson | Out-File -FilePath "$lastStateConfigProd" -Encoding utf8

        $privateConfigEndPath -replace "\\","/" | Out-File -FilePath "$Path/$ModuleName/.gitignore" -Encoding utf8
        $gitignore_content = "@
logs/*
.vscode
bin/
obj/
.ionide/
/debug/

# Visual Studio IDE directory
.vs/

# Ignore executables
*.exe
*.msi
*.appx
*.msix

# Ignore binaries and symbols
*.pdb
*.dll
*.wixpdb
@"
        $gitignore_content | Out-File -FilePath "$Path/$ModuleName/.gitignore" -Encoding utf8 -Append
        # Copy the public/exported functions into the public folder, private functions into private folder

      }
      catch {
        Write-Error $_
      }
    }
  }
  Invoke-Scaffold -ErrorAction Stop
}

