<#
.SYNOPSIS

.DESCRIPTION

#>

#Requires -Version 7.2

Param(
  [Parameter(
    HelpMessage="Source path. E.g.: 'C:\Data\Source'."
  )]
  [Alias("SRC", "Source")]
  [string]$P_PathSRC = "$($PSScriptRoot)\Source",

  [Parameter(
    HelpMessage="Destination path (Vault). E.g.: 'C:\Data\Vault'."
  )]
  [Alias("DST", "Destination")]
  [string]$P_PathDST = "$($PSScriptRoot)\Vault",

  [Parameter(
    HelpMessage="Creation expired time (in seconds). E.g.: '5270400'. Default: 61 day (5270400 sec.)."
  )]
  [Alias("CT", "CreationTime")]
  [int]$P_CreationTime = 5270400,

  [Parameter(
    HelpMessage="Last write expired time (in seconds). E.g.: '5270400'. Default: 61 day (5270400 sec.)."
  )]
  [Alias("WT", "LastWriteTime")]
  [int]$P_LastWriteTime = 5270400,

  [Parameter(
    HelpMessage="File path with excluded data. E.g.: 'C:\Data\exclude.txt'."
  )]
  [Alias("EF")]
  [string]$P_FileEXC = "$($PSScriptRoot)\vault.exclude.txt",

  [Parameter(
    HelpMessage="Logs directory path. E.g.: 'C:\Data\Logs'."
  )]
  [Alias("LOG", "Logs")]
  [string]$P_PathLogs = "$($PSScriptRoot)\Logs",

  [Parameter(
    HelpMessage="Save old files."
  )]
  [Alias("SD", "SaveData")]
  [switch]$P_SaveData = $false
)

# -------------------------------------------------------------------------------------------------------------------- #
# CONFIGURATION.
# -------------------------------------------------------------------------------------------------------------------- #

$PathSRC = "$($P_PathSRC)"
$PathDST = "$($P_PathDST)"
$TS = Get-Date -Format "yyyy-MM-dd.HH-mm-ss"
$Date = Get-Date;
$LastWriteTime = $Date.AddSeconds(-$($P_LastWriteTime))
$CreationTime = $Date.AddSeconds(-$($P_CreationTime))
$ExcludeData = Get-Content "$($P_FileEXC)"

# -------------------------------------------------------------------------------------------------------------------- #
# INITIALIZATION.
# -------------------------------------------------------------------------------------------------------------------- #

function Start-BuildVault() {
  # Run vault.
  Start-CreateDirs
  Start-MoveFiles
  Start-RemoveDirs
}

# -------------------------------------------------------------------------------------------------------------------- #
# CREATE VAULT DIRECTORIES.
# -------------------------------------------------------------------------------------------------------------------- #

function Start-CreateDirs() {
  $Dirs = @(
    "$($PathSRC)"
    "$($PathDST)"
  )

  foreach ($Dir in $Dirs) {
    if ( -not ( Test-Path "$($Dir)" ) ) { New-Item -Path "$($Dir)" -ItemType "Directory" }
  }
}

# -------------------------------------------------------------------------------------------------------------------- #
# MOVE FILES TO VAULT.
# -------------------------------------------------------------------------------------------------------------------- #

function Start-MoveFiles() {
  Write-VaultMsg -T -M "--- Moving Files..."

  $Items = Get-ChildItem -Path "$($PathSRC)" -Recurse -Exclude $ExcludeData
    | Where-Object { ( -not $_.PSIsContainer ) -and ( $_.LastWriteTime -le "$($LastWriteTime)" ) -and ( $_.CreationTime -le "$($CreationTime)" ) }

  if ( -not $Items ) { Write-VaultMsg -M "Files not found!" }

  foreach ( $Item in $Items ) {
    $Dir = "$($Item.Directory.ToString())"
    $File = "$($Item.FullName.Remove(0, $PathSRC.Length))"
    $Path = "$($PathDST)$($File)"

    Write-VaultMsg -M "[MOVE] '$($Item)' -> $($Path)"

    New-Item -Path "$($PathDST)" -ItemType "Directory" -Name "$($Dir.Remove(0, $PathSRC.Length))" -ErrorAction SilentlyContinue

    if ( ( $SaveData ) -and ( Test-Path "$($Path)" ) ) {
      Move-Item -Path "$($Path)" -Destination "$($Path).$($TS)" -Force
    }

    Move-Item -Path "$($Item.FullName)" -Destination "$($Path)" -Force
  }
}

# -------------------------------------------------------------------------------------------------------------------- #
# REMOVE EMPTY DIRECTORIES.
# -------------------------------------------------------------------------------------------------------------------- #

function Start-RemoveDirs() {
  Write-VaultMsg -T -M "--- Removing Directories..."

  $Items = Get-ChildItem -Path "$($PathSRC)" -Recurse
    | Where-Object { ( $_.PSIsContainer ) -and ( $_.LastWriteTime -le "$($LastWriteTime)" ) -and ( $_.CreationTime -le "$($CreationTime)" ) }

  if ( -not $Items ) { Write-VaultMsg -M "Directories not found!" }

  foreach ( $Item in $Items ) {
    if ( ( Get-ChildItem "$($Item)" | Measure-Object ).Count -eq 0 ) {
      Write-VaultMsg -M "[REMOVE] '$($Item)'"
      Remove-Item -Path "$($Item)" -Force
    }
  }
}

# -------------------------------------------------------------------------------------------------------------------- #
# ------------------------------------------------< COMMON FUNCTIONS >------------------------------------------------ #
# -------------------------------------------------------------------------------------------------------------------- #

function Write-VaultMsg() {
  param (
    [Alias("M")]
    [string]$Message,
    [Alias("T")]
    [switch]$Title = $false
  )

  if ( $Title ) {
    Write-Host "$($NL)$($Message)" -ForegroundColor Blue
  } else {
    Write-Host "$($Message)"
  }
}

# -------------------------------------------------------------------------------------------------------------------- #
# -------------------------------------------------< INIT FUNCTIONS >------------------------------------------------- #
# -------------------------------------------------------------------------------------------------------------------- #

Start-Transcript -Path "$($P_PathLogs)\vault.$($TS).log"
Start-BuildVault
Stop-Transcript
