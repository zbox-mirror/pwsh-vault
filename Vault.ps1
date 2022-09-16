<#
.SYNOPSIS

.DESCRIPTION

#>

#Requires -Version 7.2

Param(
  [Parameter(HelpMessage="Script work mode. Default: 'MV'.")]
  [ValidateSet("CP", "MV", "RM")]
  [Alias("M", "Mode")]
  [string]$P_Mode = "MV",

  [Parameter(HelpMessage="Source path. E.g.: 'C:\Data\Source'.")]
  [Alias("SRC", "Source")]
  [string]$P_PathSRC = "$($PSScriptRoot)\Source",

  [Parameter(HelpMessage="Destination path (Vault). E.g.: 'C:\Data\Vault'.")]
  [Alias("DST", "Destination", "Vault")]
  [string]$P_PathDST = "$($PSScriptRoot)\Vault",

  [Parameter(HelpMessage="Creation expired time (in seconds). E.g.: '5270400'. Default: 61 day (5270400 sec.).")]
  [Alias("CT", "CreationTime", "Create")]
  [long]$P_CreationTime = 5270400,

  [Parameter(HelpMessage="Last write expired time (in seconds). E.g.: '5270400'. Default: 61 day ('5270400' sec.).")]
  [Alias("WT", "LastWriteTime", "Modify")]
  [long]$P_LastWriteTime = 5270400,

  [Parameter(HelpMessage="File size check. E.g.: '5kb' / '12mb'. Default: '0kb'.")]
  [Alias("FS", "FileSize", "Size")]
  [string]$P_FileSize = "0kb",

  [Parameter(HelpMessage="File path with excluded data. E.g.: 'C:\Data\Exclude.txt'.")]
  [Alias("FE", "Exclude")]
  [string]$P_FileEXC = "$($PSScriptRoot)\Vault.Exclude.txt",

  [Parameter(HelpMessage="Logs directory path. E.g.: 'C:\Data\Logs'.")]
  [Alias("LOG", "Logs")]
  [string]$P_PathLogs = "$($PSScriptRoot)\Logs",

  [Parameter(HelpMessage="Save old files.")]
  [Alias("OW", "Overwrite")]
  [switch]$P_Overwrite = $false
)

# -------------------------------------------------------------------------------------------------------------------- #
# CONFIGURATION.
# -------------------------------------------------------------------------------------------------------------------- #

# Timestamp.
$TS = Get-Date -Format "yyyy-MM-dd.HH-mm-ss"

# New line separator.
$NL = [Environment]::NewLine

# Load functions.
. "$($PSScriptRoot)\Vault.Functions.ps1"

# -------------------------------------------------------------------------------------------------------------------- #
# INITIALIZATION.
# -------------------------------------------------------------------------------------------------------------------- #

function Start-BuildVault() {
  Start-CreateDirs
  Start-MoveFiles
  Start-RemoveDirs
}

# -------------------------------------------------------------------------------------------------------------------- #
# CREATE VAULT DIRECTORIES.
# -------------------------------------------------------------------------------------------------------------------- #

function Start-CreateDirs() {
  $Dirs = @(
    "$($P_PathSRC)"
    "$($P_PathDST)"
  )

  foreach ( $Dir in $Dirs ) {
    if ( -not ( Test-Path "$($Dir)" ) ) { New-Item -Path "$($Dir)" -ItemType "Directory" }
  }
}

# -------------------------------------------------------------------------------------------------------------------- #
# MOVE FILES TO VAULT.
# -------------------------------------------------------------------------------------------------------------------- #

function Start-MoveFiles() {
  Write-VaultMsg -T "HL" -M "Moving Files..."

  $Items = Get-ChildItem -Path "$($P_PathSRC)" -Recurse -Exclude ( Get-Content "$($P_FileEXC)" )
    | Where-Object {
        ( -not $_.PSIsContainer ) `
        -and ( $_.CreationTime -le ( Get-Date ).AddSeconds( -$($P_CreationTime) ) ) `
        -and ( $_.LastWriteTime -le ( Get-Date ).AddSeconds( -$($P_LastWriteTime) ) )
      }
    | Where-Object {
        ( $_.Length -ge "$($P_FileSize)" )
      }

  if ( -not $Items ) { Write-VaultMsg -T "I" -M "Files not found!" }

  foreach ( $Item in $Items ) {
    if ( $Item.FullName.Length -ge 245 ) {
      Write-VaultMsg -T "W" -M "'$($Item)' has over 250 characters in path! Skip..."
      continue
    }

    $Dir = "$($Item.Directory.ToString())"
    $File = "$($Item.FullName.Remove(0, $P_PathSRC.Length))"
    $Path = "$($P_PathDST)$($File)"

    switch ( $P_Mode ) {
      "CP" {
        New-SameDirectory -P "$($P_PathDST)" -N "$($Dir)"
        Backup-SameFile -P "$($Path)" -N "$($Path).VAULT.$($TS).zip"

        Write-VaultMsg -M "[CP] '$($Item)' -> '$($Path)'"
        Copy-Item -Path "$($Item.FullName)" -Destination "$($Path)" -Force
      }
      "MV" {
        New-SameDirectory -P "$($P_PathDST)" -N "$($Dir)"
        Backup-SameFile -P "$($Path)" -N "$($Path).VAULT.$($TS).zip"

        Write-VaultMsg -M "[MV] '$($Item)' -> '$($Path)'"
        Move-Item -Path "$($Item.FullName)" -Destination "$($Path)" -Force
      }
      "RM" {
        Write-VaultMsg -M "[RM] '$($Item)'"
        Remove-Item -Path "$($Item.FullName)" -Force
      }
    }
  }
}

# -------------------------------------------------------------------------------------------------------------------- #
# REMOVE EMPTY DIRECTORIES.
# -------------------------------------------------------------------------------------------------------------------- #

function Start-RemoveDirs() {
  Write-VaultMsg -T "HL" -M "Removing Directories..."

  $Items = Get-ChildItem -Path "$($P_PathSRC)" -Recurse
    | Where-Object {
        ( $_.PSIsContainer ) `
        -and ( $_.CreationTime -le ( Get-Date ).AddSeconds( -$($P_CreationTime) ) ) `
        -and ( $_.LastWriteTime -le ( Get-Date ).AddSeconds( -$($P_LastWriteTime) ) ) `
      }

  if ( -not $Items ) { Write-VaultMsg -T "I" -M "Directories not found!" }

  foreach ( $Item in $Items ) {
    if ( ( Get-ChildItem "$($Item)" | Measure-Object ).Count -eq 0 ) {
      Write-VaultMsg -M "[RM] '$($Item)'"
      Remove-Item -Path "$($Item)" -Force
    }
  }
}

# -------------------------------------------------------------------------------------------------------------------- #
# -------------------------------------------------< INIT FUNCTIONS >------------------------------------------------- #
# -------------------------------------------------------------------------------------------------------------------- #

Start-Transcript -Path "$($P_PathLogs)\vault.$($TS).log"
Start-BuildVault
Stop-Transcript
