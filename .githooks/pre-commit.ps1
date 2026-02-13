$ErrorActionPreference = "Stop"

function Write-Utf8NoBom {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Content
    )
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

$files = git diff --cached --name-only --diff-filter=ACM
if ($LASTEXITCODE -ne 0) {
    Write-Error "pre-commit: failed to list staged files."
}

$notebooks = @($files | Where-Object { $_ -match '\.ipynb$' })
if ($notebooks.Count -eq 0) {
    exit 0
}

$changedAny = $false

foreach ($nbPath in $notebooks) {
    if (-not (Test-Path -LiteralPath $nbPath)) {
        continue
    }

    try {
        $raw = Get-Content -LiteralPath $nbPath -Raw
        $nb = $raw | ConvertFrom-Json
    } catch {
        Write-Error "pre-commit: failed to parse notebook '$nbPath'."
    }

    $changed = $false

    if ($nb.cells) {
        foreach ($cell in $nb.cells) {
            if ($cell.cell_type -ne "code") {
                continue
            }

            if ($cell.PSObject.Properties.Name -contains "outputs" -and $cell.outputs -and $cell.outputs.Count -gt 0) {
                $cell.outputs = @()
                $changed = $true
            }

            if ($cell.PSObject.Properties.Name -contains "execution_count" -and $null -ne $cell.execution_count) {
                $cell.execution_count = $null
                $changed = $true
            }
        }
    }

    if ($nb.metadata -and $nb.metadata.PSObject.Properties["widgets"]) {
        $nb.metadata.PSObject.Properties.Remove("widgets")
        $changed = $true
    }

    if ($changed) {
        $json = $nb | ConvertTo-Json -Depth 100
        Write-Utf8NoBom -Path $nbPath -Content ($json + "`n")
        git add -- $nbPath
        if ($LASTEXITCODE -ne 0) {
            Write-Error "pre-commit: failed to re-stage notebook '$nbPath'."
        }
        Write-Host "pre-commit: stripped outputs from $nbPath"
        $changedAny = $true
    }
}

if ($changedAny) {
    Write-Host "pre-commit: notebook outputs were removed and re-staged."
}

exit 0
