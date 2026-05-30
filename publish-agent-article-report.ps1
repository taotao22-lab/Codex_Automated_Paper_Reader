param(
    [string]$Date = (Get-Date -Format "yyyy-MM-dd"),
    [string]$Remote = "origin",
    [string]$Branch = "main"
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$ReportDir = Join-Path $Root "docs\agent-article-reports"
$ReportPath = Join-Path $ReportDir "$Date.md"

if (-not (Test-Path -LiteralPath $ReportPath)) {
    throw "Report not found: $ReportPath"
}

git -C $Root add -- docs/agent-article-reports

$pending = git -C $Root status --porcelain -- docs/agent-article-reports
if (-not $pending) {
    Write-Output "No report changes to publish."
    exit 0
}

git -C $Root commit -m "文档：新增 $Date Agent 文章日报"
git -C $Root push $Remote $Branch
Write-Output "Published $ReportPath to $Remote/$Branch"
