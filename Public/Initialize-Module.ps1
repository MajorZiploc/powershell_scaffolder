function Initialize-Module {
param (
  [Parameter(Mandatory = $false)]
  [string]
  $Path = (Read-Host -prompt "Root path where project should be scaffolded (./): "),
  [Parameter(Mandatory = $true, HelpMessage = "May only be made up of numbers, letters, and some special characters. Regex that passes: ^[a-zA-Z]{1}[\w\d_-]+[a-zA-Z0-9]{1}$")]
  [string]
  [ValidatePattern("^[a-zA-Z]{1}[\w\d_-]+[a-zA-Z0-9]{1}$")]
  $ModuleName,
  [Parameter(Mandatory = $false)]
  [string]
  $Author = (Read-Host -prompt "Author of Project (N/A): "),
  [Parameter(Mandatory = $false)]
  [string]
  $Description = (Read-Host -prompt "Project Description (N/A): "),
  [Parameter(Mandatory = $false)]
  [string]
  $PowershellVersion = (Read-Host -prompt "Powershell Version (5.1): "),
  [Parameter(Mandatory = $false)]
  [string]
  $ModuleVersion = (Read-Host -prompt "Starting version of this project (0.1): "),
  [Parameter(Mandatory = $false)]
  [string]
  $CompanyName = (Read-Host -prompt "Company name (N/A): "),
  [Parameter(Mandatory = $false)]
  [string]
  $CopyRight = (Read-Host -prompt "Copy right (N/A): ")
)
function Invoke-Scaffold {
  [CmdletBinding()]
  param ()
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
      mkdir $Path\$ModuleName
      mkdir $Path\$ModuleName\Private
      mkdir $Path\$ModuleName\Public
      mkdir $Path\$ModuleName\en-US # For about_Help files
      mkdir $Path\$ModuleName\Tests
      mkdir $Path\$ModuleName\settings
      mkdir $Path\$ModuleName\settings\test
      mkdir $Path\$ModuleName\settings\prod

      $appConfigEndPath = "appsettings.json"
      $lastStateEndPath = "lastState.json"
      $appConfig = "$Path\$ModuleName\settings\test\$appConfigEndPath"
      $lastStateConfig = "$Path\$ModuleName\settings\test\$lastStateEndPath"
      $appConfigProd = "$Path\$ModuleName\settings\prod\$appConfigEndPath"
      $lastStateConfigProd = "$Path\$ModuleName\settings\prod\$lastStateEndPath"
      $privateConfigEndPath = "Private\config.json"
      $privateConfig = "$Path\$ModuleName\$privateConfigEndPath"
      #Create the module and related files
      New-Item "$Path\$ModuleName\$ModuleName.psm1" -ItemType File
      New-Item "$Path\$ModuleName\$ModuleName.Format.ps1xml" -ItemType File
      New-Item "$Path\$ModuleName\en-US\about_$ModuleName.help.txt" -ItemType File
      New-Item "$Path\$ModuleName\Tests\$ModuleName.Tests.ps1" -ItemType File
      New-Item "$Path\$ModuleName\Private\ErrorHandler.ps1" -ItemType File
      New-Item "$Path\$ModuleName\Private\LogHelper.ps1" -ItemType File
      New-Item "$Path\$ModuleName\Private\Program.ps1" -ItemType File
      New-Item "$Path\$ModuleName\Public\Invoke-$ModuleName.ps1" -ItemType File
      New-Item $appConfig -ItemType File
      New-Item $lastStateConfig -ItemType File
      New-Item $appConfigProd -ItemType File
      New-Item $lastStateConfigProd -ItemType File
      New-Item $privateConfig -ItemType File
      New-Item "$Path\$ModuleName\.gitignore" -ItemType File
      New-ModuleManifest -Path $Path\$ModuleName\$ModuleName.psd1 `
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
$Public = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )

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

      $moduleString > "$Path\$ModuleName\$ModuleName.psm1"

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

      $unitTestString > "$Path\$ModuleName\Tests\$ModuleName.Tests.ps1"

      $mainFile = @"
# . `$PSScriptRoot"/<private_file_name>.ps1"
# . `$PSScriptRoot"/../Public/<public_file_name>.ps1"

function Program {
  #[CmdletBinding()]
  #param (
    # [Parameter(Mandatory = `$false)]
    # [ValidateRange([int]::MinValue, 0)]
    # [int]
    # `$n = 0
  #)
  # return `$n
}
"@

      $mainFile > "$Path\$ModuleName\Private\Program.ps1"

      $runMainFile = @"
Set-StrictMode -Version 3

. `$PSScriptRoot"/../Private/Program.ps1"
. `$PSScriptRoot"/../Private/ErrorHandler.ps1"
. `$PSScriptRoot"/../Private/LogHelper.ps1"

`$environ = 'test'
`$appConfig = Get-Content -Path `$PSScriptRoot"\..\settings\`$environ\$appConfigEndPath" -Raw | ConvertFrom-Json
`$privateConfig = Get-Content -Path `$PSScriptRoot"\..\$privateConfigEndPath" -Raw | ConvertFrom-Json

`$lastStateFilePath = "`$PSScriptRoot\..\settings\`$environ\$lastStateEndPath"
`$lastState = Get-Content -Path `$lastStateFilePath -Raw | ConvertFrom-Json

# Create log directory if it does not exist, does not destroy the folder if it exists already
New-Item -ItemType Directory -Force -Path "`$PSScriptRoot/../logs" | Out-Null

`$startTime = Get-Date
`$logDate = `$startTime.ToString("yyyy-MM-dd") 
`$logFile = "`$PSScriptRoot/../logs/`$(`$appConfig.logFileName)_`$(`$logDate)_log.txt"


function Invoke-$ModuleName {
  [CmdletBinding()]
  param ()
  `$msg = "Starting process. `$(Get-Date)"
  `$msg >> `$logFile
  try {
    Program -ErrorAction Stop
  }

  catch {
    `$errorDetails = Get-ErrorDetails -error `$_
    `$msg = "Top level issue:``n"
    `$msg += `$errorDetails | ConvertTo-Json
    `$msg >> `$logFile
    throw `$_
  }

  finally {
    `$msg = "Finished process. `$(Get-Date)``n"
    `$msg >> `$logFile
    # Clean up old logs
    Clean-Logs -logFileNamePrefix `$appConfig.logFileName -keepLogsForNDays `$appConfig.keepLogsForNDays
    # update last state json
    `$lastState | ConvertTo-Json > `$lastStateFilePath
  }
}

Invoke-$ModuleName -ErrorAction Stop

"@

      $runMainFile > "$Path\$ModuleName\Public\Invoke-$ModuleName.ps1"

      $logHelper = @"

function Clean-Logs {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = `$true)]
    [string]
    `$logFileNamePrefix
    ,
    [Parameter(Mandatory = `$true)]
    [ValidateRange(0, [int]::MaxValue)]
    [int]
    `$keepLogsForNDays
  )
  [array]`$logs = Get-ChildItem -Path "`$PSScriptRoot/../logs" | Where-Object {`$_.Name -imatch "`$(`$logFileNamePrefix)_(\S+)?_log\.txt"}
  `$logs | ForEach-Object {
    `$r = (`$_.Name | Select-String -Pattern "`$(`$logFileNamePrefix)_(\S+)?_log\.txt");
    `$match = `$r.Matches.Groups[1].Value;
    [datetime]`$logDate = `$match
    `$now = Get-Date
    `$timespan = `$now - `$logDate
    `$daysOld = `$timespan.Days
    if (`$daysOld -gt `$keepLogsForNDays) {
      # delete the log file
      Remove-Item -Path `$_.FullName
    }
  }
}
"@

      $logHelper > "$Path\$ModuleName\Private\LogHelper.ps1"


      $errorHandler = @"

function Get-ErrorDetails {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory=`$true)]
    `$error
  )

  return @{
    ScriptStackTrace = `$error.ScriptStackTrace
    StackTrace = `$error.Exception.StackTrace
    Message = `$error.Exception.Message
    FullyQualifiedErrorId = `$error.FullyQualifiedErrorId
    TargetObject = `$error.TargetObject
    ErrorDetails = `$error.ErrorDetails
  }
}

"@

      $errorHandler > "$Path\$ModuleName\Private\ErrorHandler.ps1"

      $appJson = "{`"logFileName`": `"$($ModuleName)`", `"keepLogsForNDays`": 14}"
      $lastStateJson = "{`"state`": `"Any state from the last run of this program (or last update of this file) that is required for this run.`"}" 
      $privateConfigJson = "{`"password`": `"not_put_in_git`"}"

      $appJson > $appConfig
      $lastStateJson > $lastStateConfig
      $privateConfigJson > $privateConfig

      $appJson > $appConfigProd
      $lastStateJson > $lastStateConfigProd
      $privateConfigJson > $privateConfigProd

      $privateConfigEndPath -replace "\\", "/" > "$Path\$ModuleName\.gitignore"
      "$($ModuleName)*_log.txt" >> "$Path\$ModuleName\.gitignore"
      # Copy the public/exported functions into the public folder, private functions into private folder

      Set-Location $Path\$ModuleName
      @('*.ps1', '*.psd1', '*.psm1', '*.json', '*.txt', '.gitignore') `
      | ForEach-Object {
        Get-ChildItem $_ -Recurse | ForEach-Object {
          $content = Get-Content -Path $_
          Set-Content -Path $_.Fullname -Value $content -Encoding UTF8 -PassThru -Force
        }
      }

    }
    catch {
      Write-Error $_
    }
  }
}
Invoke-Scaffold -ErrorAction Stop
}
