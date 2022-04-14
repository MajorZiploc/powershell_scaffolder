. "$PSScriptRoot/../Private/ReportParserUtils.ps1"

function Write-DigestReport {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    $reportInfo
    ,
    [Parameter(Mandatory = $true)]
    [string]
    $logDir
    ,
    [Parameter(Mandatory = $true)]
    [string]
    $runSubDir
    ,
    [Parameter(Mandatory = $true)]
    [string]
    $reportOutDir
    ,
    [Parameter(Mandatory = $true)]
    [datetime]
    $startReportDate
    ,
    [Parameter(Mandatory = $true)]
    [string]
    $endReportDate
  )

  [array]$jsonInfo = $reportInfo.json
  $jsonInfo | ForEach-Object {
    $r = $null
    $filePathKeyName = if (Get-Member -InputObject $_ -Name "filePathKeyName" -MemberType Properties) { $_.filePathKeyName } else { "___Log___File___Name___" }
    $numOfLinesAfterMatch = if (Get-Member -InputObject $_ -Name "numOfLinesAfterMatch" -MemberType Properties) { $_.numOfLinesAfterMatch } else { 1 }
    $r = Get-ReportJsonDateRange -label "$($_.searchLabelPattern)" -logDir "$logDir" -runSubDir "$runSubDir" -startReportDate $startReportDate -endReportDate $endReportDate -filePathKeyName "$filePathKeyName" -numOfLinesAfterMatch $numOfLinesAfterMatch
    New-Item -ItemType Directory -Force -Path "$reportOutDir" | Out-Null
    $r | Out-File -Encoding utf8 -FilePath "$reportOutDir/$($_.fileName).json"
  }

  [array]$txtInfo = $reportInfo.txt
  $txtInfo | ForEach-Object {
    $r = $null
    $filePathKeyName = if (Get-Member -InputObject $_ -Name "filePathKeyName" -MemberType Properties) { $_.filePathKeyName } else { "File Name: " }
    $numOfLinesAfterMatch = if (Get-Member -InputObject $_ -Name "numOfLinesAfterMatch" -MemberType Properties) { $_.numOfLinesAfterMatch } else { 0 }
    $r = Get-ReportTxtDateRange -label "$($_.searchLabelPattern)" -logDir "$logDir" -runSubDir "$runSubDir" -startReportDate $startReportDate -endReportDate $endReportDate -filePathKeyName "$filePathKeyName" -numOfLinesAfterMatch $numOfLinesAfterMatch
    New-Item -ItemType Directory -Force -Path "$reportOutDir" | Out-Null
    $r | Out-File -Encoding utf8 -FilePath "$reportOutDir/$($_.fileName).txt"
  }
}
