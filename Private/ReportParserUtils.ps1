function Get-ReportJsonDateRange {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [string]
    $label
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
    [datetime]
    $startReportDate
    ,
    [Parameter(Mandatory = $true)]
    [string]
    $endReportDate
    ,
    [Parameter(Mandatory = $false)]
    [string]
    $filePathKeyName = "___Log___File___Name___"
    ,
    [Parameter(Mandatory = $false)]
    [string]
    $numOfLinesAfterMatch = 1
  )

  return Get-ReportDateRange -label "$label" -logDir "$logDir" -runSubDir "$runSubDir" -startReportDate $startReportDate -endReportDate $endReportDate -filePathKeyName "$filePathKeyName" -numOfLinesAfterMatch $numOfLinesAfterMatch -fileReportSupplier Get-ReportJsonFile | ConvertTo-Json
}

function Get-ReportTxtDateRange {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [string]
    $label
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
    [datetime]
    $startReportDate
    ,
    [Parameter(Mandatory = $true)]
    [string]
    $endReportDate
    ,
    [Parameter(Mandatory = $false)]
    [string]
    $filePathKeyName = "File Name: "
    ,
    [Parameter(Mandatory = $false)]
    [string]
    $numOfLinesAfterMatch = 0
  )

  return Get-ReportDateRange -label "$label" -logDir "$logDir" -runSubDir "$runSubDir" -startReportDate $startReportDate -endReportDate $endReportDate -filePathKeyName "$filePathKeyName" -numOfLinesAfterMatch $numOfLinesAfterMatch -fileReportSupplier Get-ReportTxtFile
}

function Get-ReportDateRange {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [string]
    $label
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
    $fileReportSupplier
    ,
    [Parameter(Mandatory = $true)]
    [datetime]
    $startReportDate
    ,
    [Parameter(Mandatory = $true)]
    [string]
    $endReportDate
    ,
    [Parameter(Mandatory = $false)]
    [string]
    $filePathKeyName = "___Log___File___Name___"
    ,
    [Parameter(Mandatory = $false)]
    [string]
    $numOfLinesAfterMatch = 1
  )

  $dayDirs = @()
  [array]$dayDirs = Get-ChildItem -Path "$logDir" | Where-Object {
    # Keep folders that can be parsed to days and are in the date range
    try {
      [datetime]$dateFolder = $_.Name
      return $dateFolder -ge $startReportDate -and $dateFolder -le $endReportDate
    } catch {
      return $false
    }
  }

  $datas = @()
  [array]$datas = $dayDirs | ForEach-Object {
    Get-ReportForDay -dayDir "$($_.FullName)/$runSubDir" -label "$label" -fileReportSupplier $fileReportSupplier -numOfLinesAfterMatch $numOfLinesAfterMatch -filePathKeyName "$filePathKeyName"
  }

  return $datas
}

function Get-ReportForDay {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [string]
    $dayDir
    ,
    [Parameter(Mandatory = $true)]
    [string]
    $label
    ,
    [Parameter(Mandatory = $true)]
    $fileReportSupplier
    ,
    [Parameter(Mandatory = $false)]
    [string]
    $filePathKeyName = "___Log___File___Name___"
    ,
    [Parameter(Mandatory = $false)]
    [string]
    $numOfLinesAfterMatch = 1
  )
  $reports = @()
  $ds = @()
  [array]$reports = Get-ChildItem -Path "$dayDir"
  [array]$ds = $reports | ForEach-Object {
    (& $fileReportSupplier -label "$label" -FilePath "$($_.FullName)" -filePathKeyName "$filePathKeyName" -numOfLinesAfterMatch $numOfLinesAfterMatch)
  } | Where-Object { $null -ne $_ }
  return $ds
}

function Get-JsonDataConverter {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [array]
    $data
    ,
    [Parameter(Mandatory = $true)]
    [string]
    $filePath
    ,
    [Parameter(Mandatory = $false)]
    [string]
    $filePathKeyName = "___Log___File___Name___"
  )

  try {
    [array]$json = $data | ForEach-Object {
      $js = @()
      [array]$js = $_ | ConvertFrom-Json
      $js
    } | ForEach-Object {
      Add-Member -InputObject $_ -NotePropertyName "$filePathKeyName" -NotePropertyValue "$filePath"
      $_
    }
    # $json = "[$($data -join ',')]" | ConvertFrom-Json
    return $json
  }
  catch {
    return $null
  }
}

function Get-TxtDataConverter {
  [CmdletBinding()]
  [OutputType([String])]
  param(
    [Parameter(Mandatory = $true)]
    [array]
    $data
    ,
    [Parameter(Mandatory = $true)]
    [string]
    $filePath
    ,
    [Parameter(Mandatory = $false)]
    [string]
    $filePathKeyName = "File Name: "
  )

  return "$($filePathKeyName)$filePath`n$($data -join '`n')"
}

function Get-ReportJsonFile {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [string]
    $label
    ,
    [Parameter(Mandatory = $true)]
    [string]
    $filePath
    ,
    [Parameter(Mandatory = $false)]
    [string]
    $filePathKeyName = "___Log___File___Name___"
    ,
    [Parameter(Mandatory = $false)]
    [string]
    $numOfLinesAfterMatch = 1
  )

  $content = Get-Content -Path "$filePath"
  $data = @()
  [array]$data = ($content | Select-String -Pattern "$label" -Context 0,$numOfLinesAfterMatch | ForEach-Object {
      $_.Context.PostContext
    })
  if ($null -eq $data) { return $null }
  $data = Get-JsonDataConverter -data $data -FilePath "$filePath" -filePathKeyName "$filePathKeyName"
  return $data
}

function Get-ReportTxtFile {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [string]
    $label
    ,
    [Parameter(Mandatory = $true)]
    [string]
    $filePath
    ,
    [Parameter(Mandatory = $false)]
    [string]
    $filePathKeyName = "File Name: "
    ,
    [Parameter(Mandatory = $false)]
    [string]
    $numOfLinesAfterMatch = 0
  )

  $content = Get-Content -Path "$filePath"
  $data = @()
  if ($numOfLinesAfterMatch -eq 0) {
    [array]$data = $content | Select-String -Pattern "$label"
  } else {
    [array]$data = ($content | Select-String -Pattern "$label" -Context 0,$numOfLinesAfterMatch | ForEach-Object {
        "$($_.Line)`n$($_.Context.PostContext -join "`n")`n"
      })
  }
  if ($null -eq $data) { return $null }
  $data = Get-TxtDataConverter -data $data -FilePath "$filePath" -filePathKeyName "$filePathKeyName"
  return $data
}
