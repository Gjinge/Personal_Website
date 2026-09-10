<#
    publish.ps1 — 一鍵發布個人網站
    流程：檢查登入 → 提交改動 → 打版本標籤 → 推送 → 等 GitHub Pages 部署完成

    用法：
        .\tools\publish.ps1 -Message "改了吃豆人進度條"
        .\tools\publish.ps1 -Message "小修字距" -NoTag      # 不打版本標籤
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Message,
    [switch]$NoTag
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $repoRoot

# 網站專用的 GitHub CLI 登入設定，並繞開失效的本機代理。
$env:GH_CONFIG_DIR = Join-Path $env:LOCALAPPDATA 'CodexWebsiteGitHubAuth'
foreach ($proxy in 'HTTP_PROXY', 'HTTPS_PROXY', 'ALL_PROXY') { Set-Item -Path "env:$proxy" -Value '' }

function Get-GitHubAccount {
    try { $name = & gh api user --jq .login 2>$null } catch { return $null }
    if ($LASTEXITCODE -ne 0) { return $null }
    return ($name | Select-Object -First 1)
}

$account = Get-GitHubAccount
if ($account -ne 'Gjinge') {
    Write-Host '尚未以 Gjinge 登入 GitHub，開始瀏覽器授權…' -ForegroundColor Yellow
    & gh auth login --hostname github.com --git-protocol https --web --skip-ssh-key
    & gh auth setup-git
    $account = Get-GitHubAccount
    if ($account -ne 'Gjinge') { throw "登入的帳號是 '$account'，不是 Gjinge，已停止，未推送任何內容。" }
}
Write-Host "GitHub 帳號：$account" -ForegroundColor DarkGray

if (& git status --porcelain) {
    & git add -A
    & git commit -m $Message
    if ($LASTEXITCODE -ne 0) { throw '提交失敗，已停止。' }
} else {
    Write-Host '沒有未提交的改動，直接推送既有提交。' -ForegroundColor DarkGray
}

$tag = $null
if (-not $NoTag) {
    $today = Get-Date -Format 'yyyy.MM.dd'
    $index = 1
    while (& git tag -l "v$today-$index") { $index++ }
    $tag = "v$today-$index"
    & git tag -a $tag -m $Message
}

& git push origin main
if ($LASTEXITCODE -ne 0) { throw '推送失敗，已停止。' }
if ($tag) { & git push origin $tag }

$runId = & gh run list --repo Gjinge/Personal_Website --limit 1 --json databaseId --jq '.[0].databaseId'
if ($runId) { & gh run watch $runId --repo Gjinge/Personal_Website --interval 10 --exit-status }

Write-Host ''
Write-Host '已上線：https://gjinge.github.io/Personal_Website/' -ForegroundColor Green
if ($tag) { Write-Host "版本標籤：$tag" -ForegroundColor Green }
Write-Host '若看到舊樣式，按 Ctrl + F5 重新整理。' -ForegroundColor DarkGray
