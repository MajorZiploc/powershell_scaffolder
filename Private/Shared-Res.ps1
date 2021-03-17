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
    `$logDir=`$logFolder
    ,
    [Parameter(Mandatory = `$false)]
    [array]
    `$excludeList=@()
  )

  `$logDates = `$null
  [array]`$logDates = Get-ChildItem -Path "`$logDir" -Exclude `$excludeList
  `$now = Get-Date
  if (`$null -eq `$logDates -or `$logDates.Length -eq 0) { return }
  `$logDates | ForEach-Object {
    `$timespan = `$null
    `$daysOld = `$null
    [datetime]`$lDate = `$_.Name
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

  return [pscustomobject]@{
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

function Write-Txt {
  [CmdletBinding()]
  param (
      [Parameter(Mandatory=`$true)]
      [string]
      `$txt
      ,
      [Parameter(Mandatory=`$false)]
      [string]
      `$logPath=`$logFile
      ,
      [Parameter(Mandatory=`$false)]
      [string]
      `$summaryPath=`$summaryFile
      ,
      [Parameter(Mandatory=`$false)]
      [string]
      `$whereToLog="11"
  )

  `$base = 2
  `$lAsInt = [convert]::ToInt32("10", `$base) # log file
  `$sAsInt = [convert]::ToInt32("01", `$base) # summary file

  if ((`$whereToLog -band `$lAsInt) -eq `$lAsInt) {
    `$txt | Out-File -FilePath "`$logFile" -Encoding utf8 -Append
  }
  if ((`$whereToLog -band `$sAsInt) -eq `$sAsInt) {
    `$txt | Out-File -FilePath "`$summaryFile" -Encoding utf8 -Append
  }
}

function Write-Json {
  [CmdletBinding()]
  param (
      [Parameter(Mandatory=`$true)]
      [string]
      `$label
      ,
      [Parameter(Mandatory=`$true)]
      `$data
      ,
      [Parameter(Mandatory=`$false)]
      [string]
      `$logPath=`$logFile
      ,
      [Parameter(Mandatory=`$false)]
      [string]
      `$summaryPath=`$summaryFile
  )

  `$label = "`$label``n"

  `$jsonc = `$data | Select-Object -Property * | ConvertTo-Json -Compress
  `$json =  `$data | Select-Object -Property * | ConvertTo-Json 
  Write-Txt -txt "`$label`$jsonc" -logPath "`$summaryFile" -whereToLog "10"
  Write-Txt -txt "`$label`$json" -logPath "`$summaryFile" -whereToLog "01"
}

"@
  return $logWriter
}

function Get-LoggingNotes {
  [CmdletBinding()]
  param ()

  $logingNotes = @"
# NOTE ON LOGGING: THESE HELPER LOGGING FUNCTIONS ARE REQUIRED TO BE USED.
# Write-Json is MUCH preferred over Write-Txt.
# When parsing the logs for data on runs of this program,
#   the json data gives us more control over the data.
# Write(append) to the log files like so:
#   For structured data (powershell custom objects): 
#      Write-Json -label "Message that appears one line before the data" -data `$data
#   For non structured data:
#      Write-Txt -txt `$msg
#      note: when using the `$msg variable to store your message. Make sure to clear out the variable like so:
#           `$msg = ""
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
# Delete old logs
    Clean-Logs -keepLogFilesForNDays `$keepLogsForNDays
"@
  return $logCleanupStep
}
