# Script de gestion des services Windows Halimou
# Usage: .\manage-services.ps1 [start|stop|restart|status]

Param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("start", "stop", "restart", "status")]
    [string]$Action,
    
    [ValidateSet("backend", "frontend", "all")]
    [string]$Service = "all"
)

$services = @{
    "backend" = "HalimouBackend"
    "frontend" = "HalimouFrontend"
}

function Get-ServiceStatus {
    param([string]$ServiceName)
    
    $svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if ($svc) {
        return $svc.Status
    }
    return "NotFound"
}

function Start-HalimouService {
    param([string]$ServiceName, [string]$DisplayName)
    
    $status = Get-ServiceStatus -ServiceName $ServiceName
    if ($status -eq "NotFound") {
        Write-Host "[ERREUR] Service $DisplayName ($ServiceName) non trouve." -ForegroundColor Red
        return $false
    }
    
    if ($status -eq "Running") {
        Write-Host "[*] $DisplayName est deja en cours d'execution." -ForegroundColor Yellow
        return $true
    }
    
    try {
        Start-Service -Name $ServiceName
        Write-Host "[OK] $DisplayName demarre..." -ForegroundColor Green
        Start-Sleep -Seconds 2
        $newStatus = Get-ServiceStatus -ServiceName $ServiceName
        if ($newStatus -eq "Running") {
            Write-Host "[OK] $DisplayName est maintenant en cours d'execution." -ForegroundColor Green
            return $true
        } else {
            Write-Host "[ERREUR] $DisplayName n'a pas pu demarrer. Statut: $newStatus" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "[ERREUR] Impossible de demarrer $DisplayName : $_" -ForegroundColor Red
        return $false
    }
}

function Stop-HalimouService {
    param([string]$ServiceName, [string]$DisplayName)
    
    $status = Get-ServiceStatus -ServiceName $ServiceName
    if ($status -eq "NotFound") {
        Write-Host "[ERREUR] Service $DisplayName ($ServiceName) non trouve." -ForegroundColor Red
        return $false
    }
    
    if ($status -eq "Stopped") {
        Write-Host "[*] $DisplayName est deja arrete." -ForegroundColor Yellow
        return $true
    }
    
    try {
        Stop-Service -Name $ServiceName -Force
        Write-Host "[OK] $DisplayName arrete..." -ForegroundColor Green
        Start-Sleep -Seconds 2
        $newStatus = Get-ServiceStatus -ServiceName $ServiceName
        if ($newStatus -eq "Stopped") {
            Write-Host "[OK] $DisplayName est maintenant arrete." -ForegroundColor Green
            return $true
        } else {
            Write-Host "[ERREUR] $DisplayName n'a pas pu etre arrete. Statut: $newStatus" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "[ERREUR] Impossible d'arreter $DisplayName : $_" -ForegroundColor Red
        return $false
    }
}

function Restart-HalimouService {
    param([string]$ServiceName, [string]$DisplayName)
    
    Write-Host "[*] Redemarrage de $DisplayName..." -ForegroundColor Yellow
    Stop-HalimouService -ServiceName $ServiceName -DisplayName $DisplayName | Out-Null
    Start-Sleep -Seconds 2
    return Start-HalimouService -ServiceName $ServiceName -DisplayName $DisplayName
}

function Show-Status {
    Write-Host "[Halimou] Statut des services" -ForegroundColor Cyan
    Write-Host "============================" -ForegroundColor Cyan
    Write-Host ""
    
    foreach ($key in $services.Keys) {
        $serviceName = $services[$key]
        $displayName = if ($key -eq "backend") { "Backend API" } else { "Frontend Web" }
        $status = Get-ServiceStatus -ServiceName $serviceName
        
        $color = switch ($status) {
            "Running" { "Green" }
            "Stopped" { "Yellow" }
            "NotFound" { "Red" }
            default { "Gray" }
        }
        
        $statusText = switch ($status) {
            "Running" { "[EN COURS]" }
            "Stopped" { "[ARRETE]" }
            "NotFound" { "[NON INSTALLE]" }
            default { "[$status]" }
        }
        
        Write-Host "  $displayName ($serviceName): " -NoNewline
        Write-Host $statusText -ForegroundColor $color
    }
    
    Write-Host ""
}

# Execution principale
Write-Host "[Halimou] Gestion des services Windows" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

if ($Action -eq "status") {
    Show-Status
    exit 0
}

$servicesToManage = @()
if ($Service -eq "all") {
    $servicesToManage = @("backend", "frontend")
} else {
    $servicesToManage = @($Service)
}

foreach ($svc in $servicesToManage) {
    $serviceName = $services[$svc]
    $displayName = if ($svc -eq "backend") { "Backend API" } else { "Frontend Web" }
    
    switch ($Action) {
        "start" {
            Start-HalimouService -ServiceName $serviceName -DisplayName $displayName
        }
        "stop" {
            Stop-HalimouService -ServiceName $serviceName -DisplayName $displayName
        }
        "restart" {
            Restart-HalimouService -ServiceName $serviceName -DisplayName $displayName
        }
    }
    
    Write-Host ""
}

if ($Action -ne "status") {
    Write-Host "[*] Statut final:" -ForegroundColor Cyan
    Show-Status
}

