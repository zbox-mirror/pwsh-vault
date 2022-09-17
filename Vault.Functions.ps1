# -------------------------------------------------------------------------------------------------------------------- #
# CREATE SIMILAR DIRECTORIES.
# -------------------------------------------------------------------------------------------------------------------- #

function New-SameDirectory() {
  param (
    [Alias("P")]
    [string]$Path,

    [Alias("N")]
    [string]$Name
  )

  New-Item -Path "$($Path)" -ItemType "Directory" `
    -Name "$($Name.Remove(0, $P_PathSRC.Length))" -ErrorAction "SilentlyContinue"
}

# -------------------------------------------------------------------------------------------------------------------- #
# BACKUP SIMILAR FILES.
# -------------------------------------------------------------------------------------------------------------------- #

function Backup-SameFile() {
  param (
    [Alias("P")]
    [string]$Path,

    [Alias("N")]
    [string]$Name
  )

  if ( ( -not $P_Overwrite ) -and ( Test-Path "$($Path)" ) ) {
    Compress-7z -T "zip" -I "$($Path)" -O "$($Name)"
  }
}

# -------------------------------------------------------------------------------------------------------------------- #
# MESSAGES.
# -------------------------------------------------------------------------------------------------------------------- #

function Write-VaultMsg() {
  param (
    [Alias("M")]
    [string]$Message,

    [Alias("T")]
    [string]$Type,

    [Alias("A")]
    [string]$Action = "Continue"
  )

  switch ( $Type ) {
    "HL" {
      Write-Host "$($NL)--- $($Message)".ToUpper() -ForegroundColor Blue
    }
    "I" {
      Write-Information -MessageData "$($Message)" -InformationAction "$($Action)"
    }
    "W" {
      Write-Warning -Message "$($Message)" -WarningAction "$($Action)"
    }
    "E" {
      Write-Error -Message "$($Message)" -ErrorAction "$($Action)"
    }
    default {
      Write-Host "$($Message)"
    }
  }
}

# -------------------------------------------------------------------------------------------------------------------- #
# 7Z ARCHIVE: COMPRESS.
# -------------------------------------------------------------------------------------------------------------------- #

function Compress-7z() {
  param (
    [Alias("I")]
    [string]$In,

    [Alias("O")]
    [string]$Out,

    [Alias("T")]
    [string]$Type
  )

  $7zParams = "a", "-t$($Type)", "$($Out)", "$($In)"
  & "$($PSScriptRoot)\_META\7z\7za.exe" @7zParams
}
