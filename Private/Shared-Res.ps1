function Get-LogHelperContent {
  [CmdletBinding()]
  param ()
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
  [array]`$logs = Get-ChildItem -Path "`$logFolder" | Where-Object {`$_.Name -imatch "`$(`$logFileNamePrefix)_(\S+)?_log\.txt"}
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