. "$PSScriptRoot/../Private/Shared-Res.ps1"

function Initialize-Script {
  param(
    [Parameter(Mandatory = $false)]
    [string]
    $Path = (Read-Host -Prompt "Root path where script should be scaffolded (./): ")
    ,
    [Parameter(Mandatory = $true,HelpMessage = "May only be made up of numbers, letters, and some special characters. Regex that passes: ^[\w\d._-]+$")]
    [string]
    [ValidatePattern("^[\w\d._-]+$")]
    $ScriptName
    ,
    [Parameter(Mandatory = $false)]
    [boolean]
    $ShouldUseAdvLogging = $false
  )
  function Invoke-Scaffold {
    [CmdletBinding()]
    param()
    process {
      try {
        if (($null -eq $Path) -or '' -eq $Path) {
          $Path = "./"
        }

        $scriptFilePath = "$Path/$ScriptName.ps1"

        New-Item "$scriptFilePath" -ItemType File

        $errorHelper = Get-ErrorHelperContent
        $startTimeInfo = Get-StartTimeInfo
        $logWriter = Get-LogWriter
        $logFolder = @"
New-Variable -Name logFolder -Value `$("./logs/`$thisScriptName") -Option ReadOnly,AllScope -Force
"@
        $logCleaner = ""
        $logCleanupStep = ""
        $logingNotes = Get-LoggingNotes

        if ($ShouldUseAdvLogging) {
          $logCleaner = Get-LogCleaner

          $logFolder = @"
New-Variable -Name logFolder -Value `$("`$PSScriptRoot/logs/`$thisScriptName") -Option ReadOnly,AllScope -Force
"@

          $logCleanupStep = Get-LogCleanupStep
        }

        $mainFile = @"
$logingNotes
Set-StrictMode -Version 1

New-Variable -Name preview -Value `$(`$true) -Option ReadOnly,AllScope -Force
$startTimeInfo
New-Variable -Name logFileName -Value `$("$ScriptName") -Option ReadOnly,AllScope -Force
New-Variable -Name summaryFolderName -Value `$("summary") -Option ReadOnly,AllScope -Force
New-Variable -Name runFolderName -Value `$("per_run") -Option ReadOnly,AllScope -Force
New-Variable -Name thisScriptName -Value `$(`$MyInvocation.MyCommand.Name -replace ".ps1", "") -Option ReadOnly,AllScope -Force
$logFolder
# Create log directory if it does not exist, does not destroy the folder if it exists already
New-Item -ItemType Directory -Force -Path "`$logFolder/`$logDate/`$runFolderName" | Out-Null
New-Item -ItemType Directory -Force -Path "`$logFolder/`$logDate/`$summaryFolderName" | Out-Null
New-Variable -Name logFile -Value `$("`$logFolder/`$logDate/`$runFolderName/`$(`$logFileName)_`$(`$logTime)_log.txt") -Option ReadOnly,AllScope -Force
New-Variable -Name summaryFile -Value `$("`$logFolder/`$logDate/`$summaryFolderName/`$(`$logFileName)_log.txt") -Option ReadOnly,AllScope -Force
New-Variable -Name keepLogsForNDays -Value `$(14) -Option ReadOnly,AllScope -Force

function Program {
  return 0
}

function Invoke-$ScriptName {
  [CmdletBinding()]
  param ()
  `$msg = "Starting process. `$(Get-Date)"
  Write-Txt -txt `$msg
  try {
    Program -ErrorAction Stop
  }

  catch {
    `$errorDetails = Get-ErrorDetail -error `$_
    Write-Json -label "Top level issue: " -data `$errorDetails
    throw `$_
  }

  finally {
    `$msg = "Finished process. `$(Get-Date)``n"
    Write-Txt -txt `$msg
    $logCleanupStep
  }
}
$errorHelper
$logCleaner
$logWriter
Invoke-$ScriptName -ErrorAction Stop

"@

        $mainFile | Out-File -FilePath "$scriptFilePath" -Encoding utf8

        $content = Get-Content -Path $scriptFilePath
        Set-Content -Path $scriptFilePath -Value $content -Encoding utf8 -Passthru -Force

      }
      catch {
        Write-Error $_
      }
    }
  }
  Invoke-Scaffold -ErrorAction Stop
}
