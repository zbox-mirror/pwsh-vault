# Windows PowerShell Vault

Скрипт для переноса и сохранения файлов в Vault (директорию хранилища), с сохранением структуры исходной директории. Может на входе принимать различные параметры фильтрации исходных файлов.

## Параметры

- `M` | `Mode`  
  Режим работы скрипта. В этом параметры можно указать режим работы скрипта. По умолчанию: `MV`.
  - `CP` - копировать файлы в Vault.
  - `MV` - перемещать файлы в Vault.
  - `RM` - удалять файлы в источнике без перемещения в Vault.
- `SRC` | `Source`  
  Путь к исходной директории (источнику). По умолчанию: `$($PSScriptRoot)\Source`.
- `DST` | `Destination` | `Vault`  
  Путь к директории назначения (Vault). По умолчанию: `$($PSScriptRoot)\Vault`.
- `CT` | `CreationTime` | `Create`  
  Время создания файла (в секундах). По умолчанию: `5270400` (61 день и более).
- `WT` | `LastWriteTime` | `Modify`  
  Время модификации файла (в секундах). По умолчанию: `5270400` (61 день и более).
- `FS` | `FileSize` | `Size`  
  Исходный размер файла. Файлы соответствующего размера и более, будут добавлены в фильтр для подготовке к переносу. По умолчанию: `0kb` и более.
  - `*kb` - размер в килобайтах.
  - `*mb` - размер в мегабайтах.
  - `*gb` - размер в гигабайтах.
  - `*tb` - размер в терабайтах.
  - `*pb` - размер в петабайтах.
- `FE` | `Exclude`  
  Путь и название файла и исключениями. По умолчанию: `$($PSScriptRoot)\Vault.Exclude.txt`.
- `LOG` | `Logs`  
  Путь к директории с журналами выполнения скрипта. По умолчанию: `$($PSScriptRoot)\Logs`.
- `OW` | `Overwrite`  
  Перезаписывать файлы в Vault. Файлы с одинаковыми именами в Vault при копировании или перемещении из источника будут перезаписаны. Если параметр не указан, файлы перед перезаписью будут архивированы с меткой времени выполнения скрипта. По умолчанию: `false`.

## Синтаксис

```
.\Vault.ps1 -SRC 'C:\Data' -DST 'C:\Vault'
```

1. Сканировать директорию `C:\Data` на файлы.
  - Время создания и изменения 61 день (и более).
2. Переместить отобранные файлы в директорию `C:\Vault` с сохранением исходной структуры.

```
.\Vault.ps1 -SRC 'C:\Data' -DST 'C:\Vault' -CT '864000' -WT '864000'
```

1. Сканировать директорию `C:\Data` на файлы.
  - Время создания и изменения 10 дней (и более).
2. Переместить отобранные файлы в директорию `C:\Vault` с сохранением исходной структуры.

```
.\Vault.ps1 -SRC 'C:\Data' -DST 'C:\Vault' -CT '864000' -WT '864000' -FS '32mb'
```

1. Сканировать директорию `C:\Data` на файлы.
  1. Время создания и изменения 10 дней (и более).
  2. Размер 32 мегабайта (и более).
2. Переместить отобранные файлы в директорию `C:\Vault` с сохранением исходной структуры.

```
.\Vault.ps1 -SRC 'C:\Data' -DST 'C:\Vault' -CT '864000' -WT '864000' -OW
```

1. Сканировать директорию `C:\Data` на файлы.
  - Время создания и изменения 10 дней (и более).
2. Переместить отобранные файлы в директорию `C:\Vault` с сохранением исходной структуры.
  - Не архивировать подобные файлы в Vault, перезаписать файлы с одинаковыми именами.
