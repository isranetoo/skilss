<#
.SYNOPSIS
  Instala skills deste repositório em ~/.claude/skills (global) ou no .claude/skills de um projeto.

.EXAMPLE
  .\install.ps1 -Global
  .\install.ps1 -Global -Skills fastapi-endpoints,commit-helper
  .\install.ps1 -Target C:\caminho\do\projeto
  .\install.ps1 -List
#>
[CmdletBinding()]
param(
    [switch]$Global,
    [string]$Target,
    [string[]]$Skills,
    [switch]$List,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$repoSkills = Join-Path $PSScriptRoot 'skills'

if (-not (Test-Path $repoSkills)) {
    throw "Pasta 'skills/' não encontrada em $PSScriptRoot"
}

$available = Get-ChildItem -Path $repoSkills -Directory |
    Where-Object { Test-Path (Join-Path $_.FullName 'SKILL.md') }

if ($List) {
    if (-not $available) { "Nenhuma skill em skills/ ainda."; return }
    foreach ($s in $available) {
        $desc = (Select-String -Path (Join-Path $s.FullName 'SKILL.md') -Pattern '^description:\s*(.+)$' |
                 Select-Object -First 1).Matches.Groups[1].Value
        "{0,-30} {1}" -f $s.Name, $desc
    }
    return
}

if ($Global) {
    $dest = Join-Path $env:USERPROFILE '.claude\skills'
} elseif ($Target) {
    if (-not (Test-Path $Target)) { throw "Destino não existe: $Target" }
    $dest = Join-Path $Target '.claude\skills'
} else {
    throw "Informe -Global, -Target <pasta> ou -List. Veja: Get-Help .\install.ps1"
}

if (-not (Test-Path $dest)) { New-Item -ItemType Directory -Path $dest -Force | Out-Null }

$toInstall = if ($Skills) {
    foreach ($name in $Skills) {
        $match = $available | Where-Object { $_.Name -eq $name }
        if (-not $match) { throw "Skill '$name' não encontrada. Rode .\install.ps1 -List" }
        $match
    }
} else { $available }

if (-not $toInstall) { "Nenhuma skill para instalar."; return }

foreach ($s in $toInstall) {
    $out = Join-Path $dest $s.Name
    if ((Test-Path $out) -and -not $Force) {
        "SKIP  $($s.Name) (já existe; use -Force para sobrescrever)"
        continue
    }
    if (Test-Path $out) { Remove-Item $out -Recurse -Force }
    Copy-Item $s.FullName $out -Recurse
    "OK    $($s.Name) -> $out"
}

""
"Instalado em: $dest"
"Reinicie o Claude Code (ou rode /skills) para carregar."
