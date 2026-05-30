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

$Prefix = -join ([char[]](0x6587, 0x6863, 0xff1a, 0x65b0, 0x589e))
$Suffix = -join ([char[]](0x6587, 0x7ae0, 0x65e5, 0x62a5))
$CommitMessage = "$Prefix $Date Agent $Suffix"
git -C $Root -c i18n.commitEncoding=utf-8 -c i18n.logOutputEncoding=utf-8 commit -m $CommitMessage
git -C $Root push $Remote $Branch
Write-Output "Published $ReportPath to $Remote/$Branch"
