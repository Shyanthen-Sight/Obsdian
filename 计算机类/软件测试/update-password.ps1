<#
.SYNOPSIS
    按当天日期生成软件测试演示环境密码，并同步更新 key.md。

.DESCRIPTION
    密码格式为 <前缀>itheima.CN032@.YYYYMMDD。
    脚本把末尾 8 位日期替换为指定日期（默认今天），并写回同目录下的 key.md。
    使用 -DryRun 可只预览、不修改文件。

.PARAMETER Date
    用于生成密码的日期，默认今天。例如：-Date 2026-10-20

.PARAMETER DryRun
    只显示将要更新的结果，不写入笔记。

.EXAMPLE
    .\update-password.ps1

.EXAMPLE
    .\update-password.ps1 -Date 2026-10-20 -DryRun
#>
[CmdletBinding()]
param(
    [datetime]$Date = (Get-Date),
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$notePath = Join-Path -Path $PSScriptRoot -ChildPath 'key.md'
if (-not (Test-Path -LiteralPath $notePath)) {
    throw "未找到笔记：$notePath"
}

$datePart = $Date.ToString('yyyyMMdd', [System.Globalization.CultureInfo]::InvariantCulture)
$pattern = '(?<prefix>(?:623|842)itheima\.CN032@\.)\d{8}'

$content = [System.IO.File]::ReadAllText($notePath, [System.Text.Encoding]::UTF8)
if ([regex]::Matches($content, $pattern).Count -eq 0) {
    throw '笔记中没有找到形如 xxxitheima.CN032@.YYYYMMDD 的密码。'
}

$newContent = [regex]::Replace($content, $pattern, '${prefix}' + $datePart)

if ($DryRun) {
    Write-Host "[试运行] 密码日期将更新为 $datePart，未写入文件。"
}
else {
    [System.IO.File]::WriteAllText(
        $notePath,
        $newContent,
        (New-Object System.Text.UTF8Encoding($false))
    )
    Write-Host "已更新 $notePath 中的密码日期为 $datePart。"
}

Write-Host ""
Write-Host "当前密码（$($Date.ToString('yyyy-MM-dd'))）："
foreach ($match in [regex]::Matches($newContent, '(?:623|842)itheima\.CN032@\.\d{8}')) {
    Write-Host "  $($match.Value)"
}
