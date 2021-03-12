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

      $logHelper = Get-LogHelperContent
      }
      else {
        $logFile = @"
`$logFile = "`$(`$logFileName)_`$(`$logDate)_log.txt"
"@
      }

      $mainFile = @"
Set-StrictMode -Version 1

`$startTime = Get-Date
`$preview = `$true
`$shouldCompressJson = `$false
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
  Write-Log -msg `$msg -logFile `$logFile
  try {
    Program -ErrorAction Stop
  }

  catch {
    `$errorDetails = Get-ErrorDetails -error `$_
    `$msg = "Top level issue:``n"
    Write-Log -msg `$msg -logFile `$logFile
    Write-Json -jsonLike `$errorDetails -logFile `$logFile -shouldCompressJson `$shouldCompressJson
    throw `$_
  }

  finally {
    `$msg = "Finished process. `$(Get-Date)``n"
    Write-Log -msg `$msg -logFile `$logFile
    $logCleanupStep
  }
}

$errorHelper

$logHelper

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
