# bootstrap.ps1
# Run in an elevated PowerShell on Windows.

$ErrorActionPreference = "Stop"

function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p  = New-Object Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Ensure-Admin {
    if (-not (Test-Admin)) {
        Write-Host "Restarting as Administrator..."
        Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
        exit
    }
}

function Refresh-Path {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("Path","User")
}

function Ensure-Choco {
    if (Get-Command choco -ErrorAction SilentlyContinue) { return }

    Write-Host "Installing Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    Refresh-Path
}

function Choco-Install {
    param([string[]]$Packages)

    Ensure-Choco
    foreach ($pkg in $Packages) {
        Write-Host "Installing $pkg ..."
        choco install $pkg -y --no-progress
    }
    Refresh-Path
}

function Install-NvmNode {
    Ensure-Choco
    if (-not (Get-Command nvm -ErrorAction SilentlyContinue)) {
        choco install nvm -y --no-progress
        Refresh-Path
    }

    Write-Host "Installing latest Node LTS via nvm..."
    nvm install lts
    nvm use lts
    Refresh-Path

    Write-Host "Node version:"
    node -v
    Write-Host "npm version:"
    npm -v
}

function Install-Basics {
    Choco-Install @(
        "git",
        "vscode",
        "python",
        "7zip",
        "googlechrome",
        "firefox",
        "notepadplusplus",
        "sysinternals",
        "curl",
        "jq",
        "ripgrep",
        "fd",
        "fzf"
    )
}

function Install-TerminalStack {
    Choco-Install @(
        "microsoft-windows-terminal",
        "powershell-core",
        "oh-my-posh"
    )
}

function Install-DevToolchains {
    Choco-Install @(
        "docker-desktop",
        "gh",
        "llvm",
        "cmake",
        "make",
        "golang",
        "rustup.install",
        "openjdk17",
        "uv",
        "pipx"
    )
}

function Install-AgenticCli {
    if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
        Install-NvmNode
    }

    Write-Host "Installing npm-based coding CLIs..."
    npm install -g @openai/codex
    npm install -g @anthropic-ai/claude-code
    npm install -g @google/gemini-cli

    Write-Host "Installing Python-based coding CLIs..."
    if (Get-Command pipx -ErrorAction SilentlyContinue) {
        pipx ensurepath
        pipx install aider-chat
    } elseif (Get-Command python -ErrorAction SilentlyContinue) {
        python -m pip install --upgrade pip
        python -m pip install aider-chat
    }

    Refresh-Path
}

function Install-Everything {
    Install-Basics
    Install-TerminalStack
    Install-NvmNode
    Install-DevToolchains
    Install-AgenticCli
}

function Show-Menu {
    Clear-Host
    Write-Host "====================================="
    Write-Host " Dev Machine Bootstrap"
    Write-Host "====================================="
    Write-Host "1. Install basics"
    Write-Host "2. Install terminal stack"
    Write-Host "3. Install Node via nvm"
    Write-Host "4. Install dev toolchains"
    Write-Host "5. Install agentic coding CLIs"
    Write-Host "6. Install EVERYTHING"
    Write-Host "7. Exit"
    Write-Host ""
}

Ensure-Admin

do {
    Show-Menu
    $choice = Read-Host "Choose an option"

    switch ($choice) {
        "1" { Install-Basics; Pause }
        "2" { Install-TerminalStack; Pause }
        "3" { Install-NvmNode; Pause }
        "4" { Install-DevToolchains; Pause }
        "5" { Install-AgenticCli; Pause }
        "6" { Install-Everything; Pause }
        "7" { break }
        default { Write-Host "Invalid option."; Start-Sleep 1 }
    }
} while ($true)