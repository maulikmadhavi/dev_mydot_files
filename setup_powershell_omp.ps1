# PowerShell Oh-My-Posh Setup Script for Windows
# This script configures oh-my-posh under PowerShell for Windows

Write-Host "🚀 Starting Oh-My-Posh setup for PowerShell..." -ForegroundColor Green

# === Step 0: Install Pixi
Write-Host "`n[*] Installing Pixi..." -ForegroundColor Cyan
# Check if Pixi is already installed
if (Get-Command pixi -ErrorAction SilentlyContinue) {
    Write-Host "[OK] Pixi is already installed." -ForegroundColor Green
} else {
    Write-Host "[*] Pixi not found. Proceeding with installation..." -ForegroundColor Yellow
    try {
    powershell -ExecutionPolicy Bypass -c "irm -useb https://pixi.sh/install.ps1 | iex"
    Write-Host "[OK] Pixi installed successfully" -ForegroundColor Green
    } catch {
        Write-Host "[!] Error installing Pixi: $_" -ForegroundColor Yellow
    }
}


pixi global install yarn git nvim python-lsp-server fzf diskus 

# === Step 1: Install oh-my-posh using winget
Write-Host "`n[*] Installing oh-my-posh..." -ForegroundColor Cyan
try {
    winget install JanDeDobbeleer.OhMyPosh -s winget -e --accept-package-agreements --accept-source-agreements
    Write-Host "[OK] oh-my-posh installed successfully" -ForegroundColor Green
} catch {
    Write-Host "[!] Error installing oh-my-posh: $_" -ForegroundColor Yellow
}

# === Step 2: Install PSReadLine module for enhanced command line experience
Write-Host "`n[*] Installing PSReadLine module..." -ForegroundColor Cyan
try {
    Install-Module -Name PSReadLine -AllowClobber -Force -SkipPublisherCheck -Scope CurrentUser
    Write-Host "[OK] PSReadLine installed successfully" -ForegroundColor Green
} catch {
    Write-Host "[!] Error installing PSReadLine: $_" -ForegroundColor Yellow
}

# === Step 3: Refresh environment variables
Write-Host "`n🔄 Refreshing environment variables..." -ForegroundColor Cyan
$env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")

# === Step 4: Get oh-my-posh themes path
Write-Host "`n[*] Getting oh-my-posh themes path..." -ForegroundColor Cyan
$poshThemesPath = (& oh-my-posh get themes-path).Trim()
if ($poshThemesPath) {
    Write-Host "Themes path: $poshThemesPath" -ForegroundColor Gray
} else {
    Write-Host "[!] Could not determine themes path" -ForegroundColor Yellow
}

# === Step 5: Create PowerShell profile if it doesn't exist
Write-Host "`n📝 Configuring PowerShell profile..." -ForegroundColor Cyan
if (-not (Test-Path $PROFILE)) {
    Write-Host "Creating PowerShell profile at: $PROFILE" -ForegroundColor Gray
    New-Item -Path $PROFILE -ItemType File -Force | Out-Null
}

# === Step 6: Add oh-my-posh initialization to profile if not already present
$profileContent = Get-Content $PROFILE -ErrorAction SilentlyContinue
if ($profileContent -notlike "*oh-my-posh*") {
    Write-Host "Adding oh-my-posh initialization to profile..." -ForegroundColor Gray
    
    # Append oh-my-posh initialization
    $initCommand = 'oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\zash.omp.json" | Invoke-Expression'
    Add-Content $PROFILE -Value $initCommand -Encoding UTF8
    
    Write-Host "[OK] Profile updated" -ForegroundColor Green
} else {
    Write-Host "[OK] oh-my-posh is already configured in the profile." -ForegroundColor Green
}

# === Step 7: Install FiraCode Nerd Font
Write-Host "`n[*] Installing FiraCode Nerd Font..." -ForegroundColor Cyan
try {
    & oh-my-posh font install FiraCode -Force
    Write-Host "[OK] FiraCode Nerd Font installed successfully" -ForegroundColor Green
} catch {
    Write-Host "[!] Error installing font: $_" -ForegroundColor Yellow
}

# === Step 8: Create custom zash theme if it doesn't exist
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

# === Final Instructions
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

# ======= Dot file management ===

Write-Host "`n[*] Installing PSDotFiles module for dotfile management..." -ForegroundColor Cyan
# First check if the module is already installed
if (Get-Module -ListAvailable -Name PSDotFiles) {
    Write-Host "[OK] PSDotFiles module is already installed." -ForegroundColor Green
} else {
    Write-Host "[*] PSDotFiles module not found. Proceeding with installation..." -ForegroundColor Yellow

    try {
        Install-Module -Name PSDotFiles -Scope CurrentUser -Force -SkipPublisherCheck
        Write-Host "[OK] PSDotFiles module installed successfully" -ForegroundColor Green
    } catch {
        Write-Host "[!] Error installing PSDotFiles: $_" -ForegroundColor Yellow
    }
}

# ==== Install nvim plug-in manager ===
# copy nvim config
Write-Host "`n[*] Setting up Neovim plug-in manager (vim-plug)..." -ForegroundColor Cyan
# copy .config/nvim/init.vim to ~/.config/nvim/init.vim
$sourceNvimConfig = ".\.config\nvim\init.vim"
$destNvimConfigDir = "$HOME\.config\nvim"
$destNvimConfig = Join-Path $destNvimConfigDir "init.vim"
if (-not (Test-Path $destNvimConfigDir)) {
    New-Item -ItemType Directory -Path $destNvimConfigDir -Force | Out-Null
}
Copy-Item -Path $sourceNvimConfig -Destination $destNvimConfig -Force
Write-Host "[OK] Neovim configuration copied successfully" -ForegroundColor Green

$plugVimPath = "$HOME\.local\share\nvim\site\autoload\plug.vim"
$plugVimDir = Split-Path $plugVimPath -Parent
if (-not (Test-Path $plugVimDir)) {
    New-Item -ItemType Directory -Path $plugVimDir -Force | Out-Null
}

Invoke-WebRequest -Uri "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim" -OutFile $plugVimPath
Write-Host "[OK] vim-plug installed successfully" -ForegroundColor Green

nvim --headless +PlugInstall +qall