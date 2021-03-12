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
    `$keepLogsForNDays
    ,
    [Parameter(Mandatory = `$true)]
    [string]
    `$logFolder
  )

  [array]`$logDates = Get-ChildItem -Path "`$logFolder"
  `$logDates | ForEach-Object {
    [datetime]`$logDate = `$_.Name
    `$now = Get-Date
    `$timespan = `$now - `$logDate
    `$daysOld = `$timespan.Days
    if (`$daysOld -gt `$keepLogsForNDays) {
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
      `$jsonLike
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

  `$jsonc = `$jsonLike | ConvertTo-Json -Compress
  `$json =  `$jsonLike | ConvertTo-Json 
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
# NOTE ON LOGGING:
# Write(append) to the log files like so:
#  logPath and summaryPath are optional. They default to the variables `$logFile and `$summaryFile
#   For non structured data:
#      Write-Log -msg `$msg -logPath "`$logFile" -summaryPath "`$summaryFile"
#   For structured data (hash maps or powershell custom objects): 
#      Write-Json -jsonLike `$data -logPath "`$logFile" -summaryPath "`$summaryFile"

"@
  return $logingNotes
}

function Get-StartTimeInfo {
  [CmdletBinding()]
  param ()

  $startTimeInfo = @"
`$startTime = Get-Date
`$logDate = `$startTime.ToString("yyyy-MM-dd") 
`$logTime = `$startTime.ToString("HH-mm-ss")
"@
  return $startTimeInfo
}
