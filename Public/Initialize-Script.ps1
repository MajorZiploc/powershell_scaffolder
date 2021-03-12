. "$PSScriptRoot/../Private/Shared-Res.ps1"

function Initialize-Script {
param (
  [Parameter(Mandatory = $false)]
  [string]
  $Path = (Read-Host -prompt "Root path where script should be scaffolded (./): ")
  ,
  [Parameter(Mandatory = $true, HelpMessage = "May only be made up of numbers, letters, and some special characters. Regex that passes: ^[a-zA-Z]{1}[\w\d_-]+[a-zA-Z0-9]{1}$")]
  [string]
  [ValidatePattern("^[a-zA-Z]*[\w\d_-]*[a-zA-Z0-9]*$")]
  $ScriptName
  ,
  [Parameter(Mandatory = $false)]
  [boolean]
  $ShouldUseAdvLogging=$false
)
function Invoke-Scaffold {
  [CmdletBinding()]
  param ()
  process {
    try {
      if (($null -eq $Path) -or '' -eq $Path) {
        $Path = "./"
      }

      $scriptFilePath = "$Path\$ScriptName.ps1"

      New-Item "$scriptFilePath" -ItemType File

      $errorHelper = Get-ErrorHelperContent
      $logWriter = Get-LogWriter
      $logFolder = @"
`$logFolder = "./logs/`$thisScriptName"
"@
      $logCleaner = ""
      $logCleanupStep = ""
      $logingNotes = Get-LoggingNotes

      if ($ShouldUseAdvLogging) {
        $logCleaner = Get-LogCleaner

        $logFolder = @"
`$logFolder = "`$PSScriptRoot/logs/`$thisScriptName"
"@

        $logCleanupStep = @"
# Clean up old logs
    Clean-Logs -keepLogsForNDays `$keepLogsForNDays -logFolder "`$logFolder"
"@
      }

      $mainFile = @"
$logingNotes
Set-StrictMode -Version 1

`$startTime = Get-Date
`$preview = `$true
`$logDate = `$startTime.ToString("yyyy-MM-dd") 
`$logTime = `$startTime.ToString("HH-mm-ss")
`$logFileName = `"$ScriptName`"
`$summaryFolderName = "summary"
`$runFolderName = "per_run"
`$thisScriptName = `$MyInvocation.MyCommand.Name -replace ".ps1", ""
$logFolder
# Create log directory if it does not exist, does not destroy the folder if it exists already
New-Item -ItemType Directory -Force -Path "`$logFolder/`$logDate/`$runFolderName" | Out-Null
New-Item -ItemType Directory -Force -Path "`$logFolder/`$logDate/`$summaryFolderName" | Out-Null
`$logFile = "`$logFolder/`$logDate/`$runFolderName/`$(`$logFileName)_`$(`$logTime)_log.txt"
`$summaryFile = "`$logFolder/`$logDate/`$summaryFolderName/`$(`$logFileName)_log.txt"
`$keepLogsForNDays = 14

function Program {
  return 0
}

function Invoke-$ScriptName {
  [CmdletBinding()]
  param ()
  `$msg = "Starting process. `$(Get-Date)"
  Write-Log -msg `$msg -logPath "`$logFile" -summaryPath "`$summaryFile"
  try {
    Program -ErrorAction Stop
  }

  catch {
    `$errorDetails = Get-ErrorDetails -error `$_
    `$msg = "Top level issue:``n"
    Write-Log -msg `$msg -logPath "`$logFile" -summaryPath "`$summaryFile"
    Write-Json -jsonLike `$errorDetails -logPath "`$logFile" -summaryPath "`$summaryFile"
    throw `$_
  }

  finally {
    `$msg = "Finished process. `$(Get-Date)``n"
    Write-Log -msg `$msg -logPath "`$logFile" -summaryPath "`$summaryFile"
    $logCleanupStep
  }
}
$errorHelper
$logCleaner
$logWriter
Invoke-$ScriptName -ErrorAction Stop

"@

      $mainFile > "$scriptFilePath"

      $content = Get-Content -Path $scriptFilePath
      Set-Content -Path $scriptFilePath -Value $content -Encoding UTF8 -PassThru -Force

    }
    catch {
      Write-Error $_
    }
  }
}
Invoke-Scaffold -ErrorAction Stop
}
