function Get-LogHelperContent {
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
    [datetime]`$logDate = `$_
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
      `$logFile
      ,
      [Parameter(Mandatory=`$false)]
      [string]
      `$summaryFile
  )

  `$msg | Out-File -FilePath "`$logFile" -Encoding utf8 -Append
  `$msg | Out-File -FilePath "`$summaryFile" -Encoding utf8 -Append
}

function Write-Json {
  [CmdletBinding()]
  param (
      [Parameter(Mandatory=`$true)]
      `$jsonLike
      ,
      [Parameter(Mandatory=`$false)]
      [string]
      `$logFile
      ,
      [Parameter(Mandatory=`$false)]
      [string]
      `$summaryFile
  )

  `$jsonc = `$jsonLike | ConvertTo-Json -Compress
  `$json =  `$jsonLike | ConvertTo-Json 
  Write-Log -msg "`$json" -logFile "`$logFile"
  Write-Log -msg "`$jsonc" -logFile "`$summaryFile"
}

"@
  return $logWriter
}
