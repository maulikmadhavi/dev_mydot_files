# PowerShell Oh-My-Posh Setup Script for Windows
# Installs the Windows toolchain and configures $PROFILE for oh-my-posh,
# Neovim, PSReadLine, and Linux-style aliases.

Write-Host "🚀 Starting Oh-My-Posh setup for PowerShell..." -ForegroundColor Green

# === Self-update (mirror of setup.sh): pull latest dotfiles so a re-run picks
# === up new files. Skipped when offline / diverged / not a git checkout.

Set-Location $PSScriptRoot
if (Test-Path (Join-Path $PSScriptRoot ".git")) {
    git pull --ff-only 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Note: could not 'git pull' (offline or diverged); continuing with the current checkout." -ForegroundColor Yellow
    }
}

# === Helpers

function Install-WithFeedback {
    param([string]$Name, [scriptblock]$Action)
    Write-Host "`n[*] Installing $Name..." -ForegroundColor Cyan
    try {
        & $Action
        Write-Host "[OK] $Name installed successfully" -ForegroundColor Green
    } catch {
        Write-Host "[!] Error installing ${Name}: $_" -ForegroundColor Yellow
    }
}

# Idempotent: appends $Content to $PROFILE only when $Marker isn't found there.
function Add-ToProfileOnce {
    param([string]$Marker, [string]$Content, [string]$Label)
    $existing = Get-Content $PROFILE -ErrorAction SilentlyContinue
    if ($existing -notlike "*$Marker*") {
        Add-Content $PROFILE -Value $Content -Encoding UTF8
        Write-Host "[OK] Added $Label to profile" -ForegroundColor Green
    } else {
        Write-Host "[OK] $Label already in profile" -ForegroundColor Green
    }
}

# === Pixi

Write-Host "`n[*] Installing Pixi..." -ForegroundColor Cyan
if (Get-Command pixi -ErrorAction SilentlyContinue) {
    Write-Host "[OK] Pixi is already installed." -ForegroundColor Green
} else {
    Install-WithFeedback "Pixi" {
        powershell -ExecutionPolicy Bypass -c "irm -useb https://pixi.sh/install.ps1 | iex"
    }
}
# Package list kept in parity with setup.sh. Differences: tmux->psmux and
# git/nvim via winget below; zsh/stow/xclip are Linux-only; xxhash/b3sum are
# skipped because utils.sh (their only consumer) is bash-only.
pixi global install yarn python-lsp-server fzf diskus tree ripgrep eza gcc gxx make cmake jq

# === Tooling installs

Install-WithFeedback "Git" {
    winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements
}
Install-WithFeedback "oh-my-posh" {
    winget install JanDeDobbeleer.OhMyPosh -s winget -e --accept-package-agreements --accept-source-agreements
}
Install-WithFeedback "PSReadLine" {
    Install-Module -Name PSReadLine -AllowClobber -Force -SkipPublisherCheck -Scope CurrentUser
}

# === Node.js via nvm-windows (mirror of setup.sh's nvm + Node LTS step;
# === nvim completion plugins need a Node runtime)

if (-not (Get-Command nvm -ErrorAction SilentlyContinue)) {
    Install-WithFeedback "nvm-windows" {
        winget install --id CoreyButler.NVMforWindows -e --source winget --accept-package-agreements --accept-source-agreements
    }
}

# === Refresh environment

Write-Host "`n🔄 Refreshing environment variables..." -ForegroundColor Cyan
$env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")

$pixiBinPath = Join-Path $HOME ".pixi\envs\nvim\Library\bin"
if ((Test-Path $pixiBinPath) -and ($env:PATH -notlike "*$pixiBinPath*")) {
    Write-Host "Adding Pixi bin path to current session: $pixiBinPath" -ForegroundColor Gray
    $env:PATH += ";$pixiBinPath"
}

# nvm-windows is on PATH after the refresh above; install/activate Node LTS.
if (Get-Command nvm -ErrorAction SilentlyContinue) {
    Install-WithFeedback "Node LTS (via nvm)" {
        nvm install lts
        nvm use lts
    }
} else {
    Write-Host "[!] nvm not found after install — open a new terminal and run 'nvm install lts'." -ForegroundColor Yellow
}

# === Locate oh-my-posh themes path

Write-Host "`n[*] Getting oh-my-posh themes path..." -ForegroundColor Cyan
$poshThemesPath = (& oh-my-posh get themes-path).Trim()
if ($poshThemesPath) {
    Write-Host "Themes path: $poshThemesPath" -ForegroundColor Gray
} else {
    Write-Host "[!] Could not determine themes path" -ForegroundColor Yellow
}

# === Ensure $PROFILE exists

Write-Host "`n📝 Configuring PowerShell profile..." -ForegroundColor Cyan
if (-not (Test-Path $PROFILE)) {
    Write-Host "Creating PowerShell profile at: $PROFILE" -ForegroundColor Gray
    New-Item -Path $PROFILE -ItemType File -Force | Out-Null
}

# === oh-my-posh init in $PROFILE

Add-ToProfileOnce -Marker 'oh-my-posh init' `
    -Content 'oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\zash.omp.json" | Invoke-Expression' `
    -Label 'oh-my-posh init'

# === Font + custom theme

Install-WithFeedback "FiraCode Nerd Font" {
    & oh-my-posh font install FiraCode -Force
}

Write-Host "`n🎨 Setting up custom theme..." -ForegroundColor Cyan
if ($poshThemesPath) {
    $themeFile = Join-Path $poshThemesPath "zash.omp.json"
    if (-not (Test-Path $themeFile)) {
        Write-Host "Creating custom theme at: $themeFile" -ForegroundColor Gray
        $themeContent = @'
{
  "$schema": "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json",
  "blocks": [
    {
      "type": "prompt",
      "alignment": "left",
      "segments": [
        {
          "type": "path",
          "style": "plain",
          "foreground": "#ffffff",
          "background": "#0077c2",
          "leading_diamond": "",
          "trailing_diamond": "",
          "properties": {
            "style": "full"
          }
        },
        {
          "type": "git",
          "style": "powerline",
          "powerline_symbol": "",
          "foreground": "#000000",
          "background": "#ffeb3b",
          "properties": {
            "branch_icon": "",
            "commit_icon": " ",
            "fetch_status": true,
            "fetch_upstream_icon": true
          }
        },
        {
          "type": "executiontime",
          "style": "powerline",
          "powerline_symbol": "",
          "foreground": "#ffffff",
          "background": "#2196f3",
          "properties": {
            "threshold": 500
          }
        }
      ]
    }
  ]
}
'@
        $themeContent | Out-File -FilePath $themeFile -Encoding UTF8
        Write-Host "[OK] Theme created successfully" -ForegroundColor Green
    } else {
        Write-Host "[OK] Custom theme already exists." -ForegroundColor Green
    }
}

# === Neovim + vim-plug

Install-WithFeedback "Neovim" {
    winget install --id Neovim.Neovim -e --source winget --accept-package-agreements --accept-source-agreements
}

Write-Host "`n[*] Setting up Neovim plug-in manager (vim-plug)..." -ForegroundColor Cyan
$destNvimConfigDir = "$HOME\.config\nvim"
if (-not (Test-Path $destNvimConfigDir)) {
    New-Item -ItemType Directory -Path $destNvimConfigDir -Force | Out-Null
}
Copy-Item -Path ".\.config\nvim\init.vim" -Destination (Join-Path $destNvimConfigDir "init.vim") -Force
Write-Host "[OK] Neovim configuration copied successfully" -ForegroundColor Green

$plugVimPath = "$HOME\.local\share\nvim\site\autoload\plug.vim"
$plugVimDir = Split-Path $plugVimPath -Parent
if (-not (Test-Path $plugVimDir)) {
    New-Item -ItemType Directory -Path $plugVimDir -Force | Out-Null
}
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim" -OutFile $plugVimPath
Write-Host "[OK] vim-plug installed successfully" -ForegroundColor Green

if (Get-Command nvim -ErrorAction SilentlyContinue) {
    Add-ToProfileOnce -Marker 'Set-Alias vim nvim' `
        -Content 'Set-Alias vim nvim' `
        -Label "alias 'vim=nvim'"

    # Mirror of setup.sh: install nvim plugins headlessly so first launch is ready.
    Write-Host "`n[*] Installing nvim plugins (PlugInstall)..." -ForegroundColor Cyan
    nvim --headless +PlugInstall +qall 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] nvim plugins installed" -ForegroundColor Green
    } else {
        Write-Host "[!] nvim PlugInstall had issues; run :PlugInstall inside nvim later." -ForegroundColor Yellow
    }
} else {
    Write-Host "[!] nvim executable not found. Skipping alias + plugin setup." -ForegroundColor Yellow
}

# === tmux for Windows

if (Get-Command choco -ErrorAction SilentlyContinue) {
    choco install psmux -y
} else {
    Write-Host "[!] Chocolatey not found — skipping psmux (tmux for Windows). Install choco and re-run if you want it." -ForegroundColor Yellow
}

# === PSReadLine config

Write-Host "`n[*] Configuring PSReadLine (IntelliSense)..." -ForegroundColor Cyan
$psReadlineConfig = @'
# PSReadLine Autocomplete
if (Get-Command Set-PSReadLineOption -ErrorAction SilentlyContinue) {
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -Colors @{ InlinePrediction = 'DarkGreen' }
    Set-PSReadLineOption -PredictionViewStyle InlineView
}
'@
Add-ToProfileOnce -Marker 'Set-PSReadLineOption -PredictionSource' `
    -Content "`n$psReadlineConfig" `
    -Label 'PSReadLine config'

try {
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -Colors @{ InlinePrediction = 'DarkGreen' }
    Set-PSReadLineOption -PredictionViewStyle InlineView
    Write-Host "[OK] Enabled Predictive IntelliSense" -ForegroundColor Green
} catch {
    Write-Host "[!] Error setting PSReadLine options: $_" -ForegroundColor Yellow
}

# === Linux/Unix utility aliases (idempotent — won't duplicate on re-run)

$linuxAliases = @(
    'function cp { Copy-Item @args }',
    'function mv { Move-Item @args }',
    'function rm { Remove-Item @args }',
    'function ls { Get-ChildItem @args }',
    'function cat { Get-Content @args }',
    'function pwd { Get-Location }',
    'function cd.. { Set-Location .. }',
    'Set-Alias -Name grep -Value Select-String -Force -Scope Global',
    'function clear { Clear-Host }'
)
$existing = Get-Content $PROFILE -ErrorAction SilentlyContinue
foreach ($line in $linuxAliases) {
    if ($existing -notlike "*$line*") {
        Add-Content $PROFILE -Value $line -Encoding UTF8
    }
}
Write-Host "[OK] Linux/Unix utility aliases configured" -ForegroundColor Green

# === Final banner

Write-Host "`n" -ForegroundColor Green
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║              Oh-My-Posh Setup Complete!                   ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "  1. FiraCode Nerd Font has been installed" -ForegroundColor White
Write-Host "  2. Configure your terminal to use FiraCode Nerd Font" -ForegroundColor White
Write-Host "  3. Close and reopen PowerShell to see the new theme in action" -ForegroundColor White
Write-Host "`nTo view available themes, run:" -ForegroundColor Cyan
Write-Host "   oh-my-posh get themes" -ForegroundColor Gray
Write-Host "`n"
