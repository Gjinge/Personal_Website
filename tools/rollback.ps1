<#
    rollback.ps1 — 安全回退到舊版本（完整保留歷史，不會抹掉任何提交）

    用法：
        .\tools\rollback.ps1                          列出最近的版本
        .\tools\rollback.ps1 -To v2026.09.10-1 -Preview   只在本機預覽那一版
        .\tools\rollback.ps1 -To v2026.09.10-1        把網站內容還原成那一版
#>
[CmdletBinding()]
param(
    [string]$To,
    [switch]$Preview
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $repoRoot

if (-not $To) {
    Write-Host '版本標籤：' -ForegroundColor Cyan
    $tags = & git tag --sort=-creatordate
    if ($tags) { $tags | Select-Object -First 20 | ForEach-Object { '  {0}' -f $_ } } else { Write-Host '  (還沒有標籤，用 publish.ps1 發布就會自動產生)' -ForegroundColor DarkGray }
    Write-Host ''
    Write-Host '最近的提交：' -ForegroundColor Cyan
    & git log --oneline --decorate -20 | ForEach-Object { '  {0}' -f $_ }
    Write-Host ''
    Write-Host '預覽某一版： .\tools\rollback.ps1 -To <標籤或前七碼> -Preview' -ForegroundColor DarkGray
    Write-Host '回退到某一版：.\tools\rollback.ps1 -To <標籤或前七碼>' -ForegroundColor DarkGray
    return
}

& git rev-parse --verify --quiet "$To^{commit}" > $null
if ($LASTEXITCODE -ne 0) { throw "找不到版本 '$To'。先不加參數執行一次，看看有哪些版本。" }

if (& git status --porcelain) { throw '工作區還有未提交的改動，請先提交或還原，再執行回退。' }

if ($Preview) {
    & git switch --detach $To
    Write-Host ''
    Write-Host "已切換到 $To（只在本機，不影響線上）。" -ForegroundColor Green
    Write-Host '直接開 index.html 看效果。看完回到最新版： git switch main' -ForegroundColor DarkGray
    return
}

$behind = & git rev-list --count "$To..HEAD"
if ([int]$behind -eq 0) { Write-Host "目前已經就是 $To 的內容，不需要回退。" -ForegroundColor Yellow; return }

Write-Host "將撤銷 $To 之後的 $behind 個提交的內容（歷史保留，可再回退回來）。" -ForegroundColor Yellow
& git revert --no-commit "$To..HEAD"
if ($LASTEXITCODE -ne 0) { throw '回退過程有衝突，請手動處理後 git revert --continue，或用 git revert --abort 取消。' }
& git commit -m "Roll back site content to $To"

Write-Host ''
Write-Host "本機已還原成 $To 的內容。確認沒問題後上線：" -ForegroundColor Green
Write-Host "  .\tools\publish.ps1 -Message ""Roll back to $To""" -ForegroundColor Cyan
