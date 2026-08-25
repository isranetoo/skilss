<#
.SYNOPSIS
  Instalador remoto: baixa skills de github.com/isranetoo/skilss sem precisar clonar o repo.

.EXAMPLE
  # tudo, global (~/.claude/skills)
  irm https://raw.githubusercontent.com/isranetoo/skilss/main/get.ps1 | iex

  # uma skill especifica
  $env:SKILLS='grill-me'; irm https://raw.githubusercontent.com/isranetoo/skilss/main/get.ps1 | iex

  # com parametros nomeados
  & ([scriptblock]::Create((irm https://raw.githubusercontent.com/isranetoo/skilss/main/get.ps1))) -Skills grill-me -Force
#>
[CmdletBinding()]
param(
    [string[]]$Skills,
    [string]$Target,
    [string]$Ref = 'main',
    [switch]$Force,
    [switch]$List
)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Permite uso via `$env:SKILLS='a,b'; irm ... | iex` (pipe nao aceita parametros nomeados)
if (-not $Skills -and $env:SKILLS)        { $Skills = $env:SKILLS -split '\s*,\s*' }
if (-not $Target -and $env:SKILLS_TARGET) { $Target = $env:SKILLS_TARGET }
if (-not $PSBoundParameters.ContainsKey('Ref') -and $env:SKILLS_REF) { $Ref = $env:SKILLS_REF }
if (-not $Force -and $env:SKILLS_FORCE)   { $Force = $true }

$repo   = 'isranetoo/skilss'
$zipUrl = "https://github.com/$repo/archive/refs/heads/$Ref.zip"
$tmp    = Join-Path ([System.IO.Path]::GetTempPath()) ("skilss-" + [guid]::NewGuid().ToString('N'))
$zip    = "$tmp.zip"

if ($Target) {
    if (-not (Test-Path $Target)) { throw "Destino nao existe: $Target" }
    $dest = Join-Path $Target '.claude\skills'
} else {
    $dest = Join-Path $env:USERPROFILE '.claude\skills'
}

Write-Host "Baixando $repo@$Ref ..."
try {
    Invoke-WebRequest -Uri $zipUrl -OutFile $zip -UseBasicParsing
    New-Item -ItemType Directory -Path $tmp -Force | Out-Null
    Expand-Archive -Path $zip -DestinationPath $tmp -Force

    $src = Get-ChildItem -Path $tmp -Directory | Select-Object -First 1
    $skillsDir = Join-Path $src.FullName 'skills'
    if (-not (Test-Path $skillsDir)) { throw "O repo nao contem a pasta 'skills/' no ref '$Ref'." }

    $available = Get-ChildItem -Path $skillsDir -Directory |
        Where-Object { Test-Path (Join-Path $_.FullName 'SKILL.md') }

    if ($List) {
        if (-not $available) { Write-Host "Nenhuma skill publicada ainda."; return }
        foreach ($s in $available) {
            $m = Select-String -Path (Join-Path $s.FullName 'SKILL.md') -Pattern '^description:\s*(.+)$' | Select-Object -First 1
            $desc = if ($m) { $m.Matches.Groups[1].Value } else { '' }
            Write-Host ("{0,-20} {1}" -f $s.Name, $desc)
        }
        return
    }

    $toInstall = if ($Skills) {
        foreach ($name in $Skills) {
            $match = $available | Where-Object { $_.Name -eq $name }
            if (-not $match) { throw "Skill '$name' nao existe. Disponiveis: $($available.Name -join ', ')" }
            $match
        }
    } else { $available }

    if (-not $toInstall) { Write-Host "Nada para instalar."; return }
    if (-not (Test-Path $dest)) { New-Item -ItemType Directory -Path $dest -Force | Out-Null }

    foreach ($s in $toInstall) {
        $out = Join-Path $dest $s.Name
        if ((Test-Path $out) -and -not $Force) {
            Write-Host "SKIP  $($s.Name) (ja existe; use -Force)"
            continue
        }
        if (Test-Path $out) { Remove-Item $out -Recurse -Force }
        Copy-Item $s.FullName $out -Recurse
        Write-Host "OK    $($s.Name)"
    }

    Write-Host ""
    Write-Host "Instalado em: $dest"
    Write-Host "Reinicie o Claude Code para carregar."
}
finally {
    Remove-Item $zip -Force -ErrorAction SilentlyContinue
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
