<#
    Bootstrap script to check if nodejs is installed and install it if not.
    After installation, it will install the required npm packages.
#>

# Check if Chocolatey is installed
if (-not (& {choco -v})) {
    # Chocolatey is not installed
    Write-Output -InputObject 'Chocolatey is not installed. Installing Chocolatey...'

    # Download and install Chocolatey
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    
} else {
    # Chocolatey is installed
    Write-Output -InputObject 'Chocolatey is installed.'
}

# Check if nodejs is installed
if (-not (& {npm -v})) {
    # Install nodejs
    choco install nodejs -y
}
else {
    # nodejs is installed
    Write-Output -InputObject 'nodejs is installed.'
}

# Check if mermaid-cli is installed, based on command "npm -v"
if (-not (& {mmdc -h})) {
    # Install mermaid-cli
    npm install -g @mermaid-js/mermaid-cli
}
else {
    # mermaid-cli is installed
    Write-Output -InputObject 'mermaid-cli is installed.'
}