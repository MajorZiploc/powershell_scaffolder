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

      $logFile = ""
      $logHelper = ""
      $logCleanupStep = ""
      if ($ShouldUseAdvLogging) {
        $logFile = @"
`$logFolder = "`$PSScriptRoot/logs"
# Create log directory if it does not exist, does not destroy the folder if it exists already
New-Item -ItemType Directory -Force -Path "`$logFolder" | Out-Null
`$logFile = "`$logFolder/`$logFileName/`$(`$logFileName)_`$(`$logDate)_log.txt"
`$keepLogsForNDays = 14
"@
        $logCleanupStep = @"

    # Clean up old logs
    Clean-Logs -logFileNamePrefix `$logFileName -keepLogsForNDays `$keepLogsForNDays -logFolder "`$logFolder"
"@

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
    ,
    [Parameter(Mandatory = `$true)]
    [string]
    `$logFolder
  )
  [array]`$logs = Get-ChildItem -Path "`$logFolder/`$logFileName" | Where-Object {`$_.Name -imatch "`$(`$logFileNamePrefix)_(\S+)?_log\.txt"}
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

      }
      else {
        $logFile = @"
`$logFile = "`$(`$logFileName)_`$(`$logDate)_log.txt"
"@
      }

      $mainFile = @"
Set-StrictMode -Version 1

`$startTime = Get-Date
`$logDate = `$startTime.ToString("yyyy-MM-dd") 
`$logFileName = `"$ScriptName`"
$logFile

function Program {
  return 0
}

function Invoke-$ScriptName {
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
    $logCleanupStep
  }
}

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

$logHelper

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
