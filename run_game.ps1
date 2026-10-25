$ErrorActionPreference = "Stop"

$Project = "C:\AshenKingdom"
$Godot = "C:\Users\super\OneDrive\Documents\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe"
$Stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$Logs = Join-Path $Project "logs"
$Backup = Join-Path $Project "backups\run_check_$Stamp"

if (!(Test-Path (Join-Path $Project "project.godot"))) {
    throw "Не найден project.godot."
}
if (!(Test-Path $Godot)) {
    throw "Не найден исполняемый файл Godot."
}

New-Item -ItemType Directory -Force -Path $Logs, $Backup | Out-Null
Set-Location $Project

# Сохраняем текущий скрипт врага, ничего не переписывая.
$Enemy = Join-Path $Project "enemy_ai.gd"
if (Test-Path $Enemy) {
    Copy-Item -LiteralPath $Enemy -Destination (Join-Path $Backup "enemy_ai.gd")
}

Write-Host "`n=== Проверка AshenKingdom ===" -ForegroundColor Cyan
Write-Host "Проект: $Project"
Write-Host "Godot: 4.7.2"
Write-Host "Резервная копия: $Backup"

# Сначала проверяем загрузку игровой сцены без графического окна.
$OutLog = Join-Path $Logs "run_check_$Stamp.out.log"
$ErrLog = Join-Path $Logs "run_check_$Stamp.err.log"

$Proc = Start-Process -FilePath $Godot `
    -ArgumentList @("--headless", "--path", $Project, "--quit-after", "5") `
    -RedirectStandardOutput $OutLog `
    -RedirectStandardError $ErrLog `
    -Wait -PassThru

$Output = ""
if (Test-Path $OutLog) {
    $Output += [System.IO.File]::ReadAllText($OutLog)
}
if (Test-Path $ErrLog) {
    $Output += "`n" + [System.IO.File]::ReadAllText($ErrLog)
}

Write-Host "`n=== Результат проверки ===" -ForegroundColor Cyan
$Important = $Output -split "`r?`n" |
    Where-Object {
        $_ -match 'SCRIPT ERROR|Parse Error|Could not preload|Failed to load script|\[enemy\]|\[БОЙ\]'
    } |
    Select-Object -First 40

if ($Important) {
    $Important | ForEach-Object { Write-Host $_ }
} else {
    Write-Host "Важных сообщений нет. Проверь журналы при подозрении на ошибку."
}

if ($Proc.ExitCode -ne 0 -or
    $Output -match 'SCRIPT ERROR|Parse Error|Could not preload resource script|Failed to load script') {
    Write-Host "`nПроверка не пройдена. Игру не запускаю." -ForegroundColor Red
    Write-Host "Журнал: $OutLog"
    Write-Host "Ошибки: $ErrLog"
    exit 1
}

Write-Host "`nПроверка загрузки пройдена. Запускаю игру..." -ForegroundColor Green

# Открываем именно игру, а не редактор Godot.
Start-Process -FilePath $Godot -ArgumentList @("--path", $Project)

Write-Host "Игровое окно запущено."
Write-Host "Логи проверки: $OutLog ; $ErrLog"
Write-Host "Файлы проекта не изменялись. Git commit и push не выполнялись."