function Get-LogCleaner {
  [CmdletBinding()]
  param ()
  $logHelper = @"

function Clean-Logs {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = `$true)]
    [ValidateRange(0, [int]::MaxValue)]
    [int]
    `$keepLogFilesForNDays
    ,
    [Parameter(Mandatory = `$false)]
    [string]
    `$logDir
  )

  `$logDir = if ([string]::IsNullOrWhiteSpace(`$logDir)) { `$logFolder } else { `$logDir }
  [array]`$logDates = Get-ChildItem -Path "`$logFolder"
  `$logDates | ForEach-Object {
    [datetime]`$lDate = `$_.Name
    `$now = Get-Date
    `$timespan = `$now - `$lDate
    `$daysOld = `$timespan.Days
    if (`$daysOld -gt `$keepLogFilesForNDays) {
      # delete the log date folder
      Remove-Item -Path `$_.FullName -Recurse
    }
  }
}

"@

  return $logHelper
}

function Get-ErrorHelperContent {
  [CmdletBinding()]
  param ()
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

  return $errorHandler
}


function Get-LogWriter {
  [CmdletBinding()]
  param ()
  $logWriter = @"

function Write-Log {
  [CmdletBinding()]
  param (
      [Parameter(Mandatory=`$true)]
      [string]
      `$msg
      ,
      [Parameter(Mandatory=`$false)]
      [string]
      `$logPath
      ,
      [Parameter(Mandatory=`$false)]
      [string]
      `$summaryPath
      ,
      [Parameter(Mandatory=`$false)]
      [string]
      `$whereToLog="11"
  )

  `$lf = if ([string]::IsNullOrWhiteSpace(`$logPath)) { `$logFile } else { `$logPath }
  `$sf = if ([string]::IsNullOrWhiteSpace(`$summaryPath)) { `$summaryFile } else { `$summaryPath }
  `$base = 2
  `$lAsInt = [convert]::ToInt32("10", `$base) # log file
  `$sAsInt = [convert]::ToInt32("01", `$base) # summary file

  if ((`$whereToLog -band `$lAsInt) -eq `$lAsInt) {
    `$msg | Out-File -FilePath "`$logFile" -Encoding utf8 -Append
  }
  if ((`$whereToLog -band `$sAsInt) -eq `$sAsInt) {
    `$msg | Out-File -FilePath "`$summaryFile" -Encoding utf8 -Append
  }
}

function Write-Json {
  [CmdletBinding()]
  param (
      [Parameter(Mandatory=`$true)]
      `$data
      ,
      [Parameter(Mandatory=`$false)]
      [string]
      `$logPath
      ,
      [Parameter(Mandatory=`$false)]
      [string]
      `$summaryPath
  )

  `$lf = if ([string]::IsNullOrWhiteSpace(`$logPath)) { `$logFile } else { `$logPath }
  `$sf = if ([string]::IsNullOrWhiteSpace(`$summaryPath)) { `$summaryFile } else { `$summaryPath }

  `$jsonc = `$data | Select-Object -Property * | ConvertTo-Json -Compress
  `$json =  `$data | Select-Object -Property * | ConvertTo-Json 
  Write-Log -msg "`$jsonc" -logPath "`$summaryFile" -whereToLog "10"
  Write-Log -msg "`$json" -logPath "`$summaryFile" -whereToLog "01"
}

"@
  return $logWriter
}

function Get-LoggingNotes {
  [CmdletBinding()]
  param ()

  $logingNotes = @"
# NOTE ON LOGGING: THESE HELPER LOGGING FUNCTIONS ARE REQUIRED TO BE USED.
# Write(append) to the log files like so:
#   For non structured data:
#      Write-Log -msg `$msg
#   For structured data (hash maps or powershell custom objects): 
#      Write-Json -data `$data
#   note: when using the `$msg variable to store your message. Make sure to clear out the variable like so:
#        `$msg = ""
# Why do I have to use these for logging?
# These helper functions use the utf-8 writing format which is required to parse the logs
# Default writing format is utf-16 for powershell 5.1 and lower.
#   This is the binary format, and not consumed as text by other programs
# These helper functions also write to multiple files in different formats depending on the file

"@
  return $logingNotes
}

function Get-StartTimeInfo {
  [CmdletBinding()]
  param ()

  $startTimeInfo = @"
New-Variable -Name startTime -Value `$(Get-Date) -Option ReadOnly,AllScope -Force
New-Variable -Name logDate -Value `$(`$startTime.ToString("yyyy-MM-dd")) -Option ReadOnly,AllScope -Force
New-Variable -Name logTime -Value `$(`$startTime.ToString("HH-mm-ss")) -Option ReadOnly,AllScope -Force
"@
  return $startTimeInfo
}

function Get-BlackListedVars {
  [CmdletBinding()]
  param ()

  $blackListedVars = @"

These variables are set in the public invoke functions
If they are overridden, then it can lead to unexpected behavior

DO NOT USE THE FOLLOWING VARIABLES.

  `$appConfig
  `$lastState
  `$lastStateFilePath
  `$thisScriptName 
  `$settingsFolder
  `$secrets 
  `$logFile
  `$logFolder
  `$logDate
  `$logTime
  `$logFile
  `$summaryFile
  `$environ
  `$startTime

FAQ:
Why are these variables written to with force and are read-only? Why not use constants?
  In some run environments, marking these variables as constants/read-only will throw errors if the program is run multiple times
  That is why we are using read-only and setting them with force

"@
  return $blackListedVars
}


function Get-LogCleanupStep {
  [CmdletBinding()]
  param ()

  $logCleanupStep = @"
# Clean up old logs
    Clean-Logs -keepLogFilesForNDays `$keepLogsForNDays
"@
  return $logCleanupStep
}
