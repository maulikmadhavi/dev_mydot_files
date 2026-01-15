Set-Alias vim nvim

# PSReadLine Autocomplete
if (Get-Command Set-PSReadLineOption -ErrorAction SilentlyContinue) {
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -Colors @{ InlinePrediction = 'DarkGreen' }
    Set-PSReadLineOption -PredictionViewStyle InlineView
}
function cp { Copy-Item @args }
function mv { Move-Item @args }
function rm { Remove-Item @args }
function ls { Get-ChildItem @args }
function cat { Get-Content @args }
function pwd { Get-Location }
function cd.. { Set-Location .. }
Set-Alias -Name grep -Value Select-String -Force -Scope Global
function clear { Clear-Host }
# Remove invalid conda paths before initialization
Set-Alias vim nvim

# PSReadLine Autocomplete
if (Get-Command Set-PSReadLineOption -ErrorAction SilentlyContinue) {
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -Colors @{ InlinePrediction = 'DarkGreen' }
    Set-PSReadLineOption -PredictionViewStyle InlineView
}
function cp { Copy-Item @args }
function mv { Move-Item @args }
function rm { Remove-Item @args }
function ls { Get-ChildItem @args }
function cat { Get-Content @args }
function pwd { Get-Location }
function cd.. { Set-Location .. }
Set-Alias -Name grep -Value Select-String -Force -Scope Global
function clear { Clear-Host }
Set-Alias vim nvim

# PSReadLine Autocomplete
if (Get-Command Set-PSReadLineOption -ErrorAction SilentlyContinue) {
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -Colors @{ InlinePrediction = 'DarkGreen' }
    Set-PSReadLineOption -PredictionViewStyle InlineView
}
function cp { Copy-Item @args }
function mv { Move-Item @args }
function rm { Remove-Item @args }
function ls { Get-ChildItem @args }
function cat { Get-Content @args }
function pwd { Get-Location }
function cd.. { Set-Location .. }
Set-Alias -Name grep -Value Select-String -Force -Scope Global
function clear { Clear-Host }

# Oh-My-Posh initialization
oh-my-posh init pwsh --config 'C:\Program Files (x86)\oh-my-posh\themes\zash.omp.json' | Invoke-Expression
Set-Alias vim nvim

# PSReadLine Autocomplete
if (Get-Command Set-PSReadLineOption -ErrorAction SilentlyContinue) {
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -Colors @{ InlinePrediction = 'DarkGreen' }
    Set-PSReadLineOption -PredictionViewStyle InlineView
}
function cp { Copy-Item @args }
function mv { Move-Item @args }
function rm { Remove-Item @args }
function ls { Get-ChildItem @args }
function cat { Get-Content @args }
function pwd { Get-Location }
function cd.. { Set-Location .. }
Set-Alias -Name grep -Value Select-String -Force -Scope Global
function clear { Clear-Host }
