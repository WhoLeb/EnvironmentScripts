function Add-Path {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Alias('p')]
        [string]$Path,

        [Alias('u')]
        [switch]$User,

        [Alias('g')]
        [switch]$Global,

        [Alias('r')]
        [switch]$Process,

        [Alias('s')]
        [ValidateSet('User', 'Machine', 'Process')]
        [string[]]$Setting,

        [Alias('h')]
        [switch]$Help
    )

    $helpText = @'
Add-Path, add-path, ap

Adds a directory to PATH.

Usage:
  Add-Path -p     <path> [-u]     [-g]       [-r]        [-s        User|Machine|Process]
  Add-Path --path <path> [--user] [--global] [--process] [--setting User|Machine|Process]
  Add-Path -h

Flags:
  -p, --path      Path to add. Can be relative; will be resolved to a full path.
  -u, --user      Add to the current user's PATH.
  -g, --global    Add to the machine PATH.
  -r, --process   Add to the current process PATH only.
  -s, --setting   Explicitly specify User, Machine, or Process.
  -h, --help      Show this help text.

Rules:
  - If no arguments are provided, help is shown.
  - If any scope flag is provided, path is mandatory.
  - Multiple scopes may be used together.
  - Duplicate PATH entries are not added.
  - Machine scope requires elevation.

Examples:
  Add-Path -h
  Add-Path -p .\bin -u
  Add-Path --path C:\Tools\Git\bin --global
  Add-Path -p ..\scripts -u -r
  Add-Path -p C:\MyTool -s User -s Process
'@

    $noArguments =
        -not $PSBoundParameters.ContainsKey('Path')    -and
        -not $PSBoundParameters.ContainsKey('User')    -and
        -not $PSBoundParameters.ContainsKey('Global')  -and
        -not $PSBoundParameters.ContainsKey('Process') -and
        -not $PSBoundParameters.ContainsKey('Setting') -and
        -not $PSBoundParameters.ContainsKey('Help')

    if ($Help -or $noArguments) {
        $helpText
        return
    }

    $scopeRequested =
        $User -or $Global -or $Process -or $PSBoundParameters.ContainsKey('Setting')

    if ($scopeRequested -and [string]::IsNullOrWhiteSpace($Path)) {
        throw "Path is mandatory when any scope flag is used."
    }

    if ([string]::IsNullOrWhiteSpace($Path)) {
        $helpText
        return
    }

    try {
        $resolvedPath = (Resolve-Path -LiteralPath $Path -ErrorAction Stop).Path
    }
    catch {
        throw "Could not resolve path '$Path'. The path must already exist."
    }

    $scopes = New-Object System.Collections.Generic.List[string]

    if ($User)    { [void]$scopes.Add('User') }
    if ($Global)  { [void]$scopes.Add('Machine') }
    if ($Process) { [void]$scopes.Add('Process') }
    if ($Setting) { [void]$scopes.AddRange($Setting) }

    if ($scopes.Count -eq 0) {
        [void]$scopes.Add('Machine')
    }

    $scopes = $scopes | Select-Object -Unique

    if (-not $scopes.Count) {
        $helpText
        return
    }

    foreach ($scope in $scopes) {
        $current = [Environment]::GetEnvironmentVariable('Path', $scope)

        $entries =
            if ([string]::IsNullOrWhiteSpace($current)) {
                @()
            }
            else {
                $current -split ';' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
            }

        $alreadyExists = $false
        foreach ($entry in $entries) {
            if ([System.StringComparer]::OrdinalIgnoreCase.Equals($entry, $resolvedPath)) {
                $alreadyExists = $true
                break
            }
        }

        if ($alreadyExists) {
            Write-Host "[$scope] Already present: $resolvedPath"
            continue
        }

        $newValue =
            if ($entries.Count -eq 0) {
                $resolvedPath
            }
            else {
                ($entries + $resolvedPath) -join ';'
            }

        try {
            [Environment]::SetEnvironmentVariable('Path', $newValue, $scope)
            Write-Host "[$scope] Added: $resolvedPath"
        }
        catch {
            throw "Failed to update PATH for scope '$scope'. For Machine scope, run PowerShell as Administrator."
        }
    }

    $updatedPersistentScope = $scopes -contains 'User' -or $scopes -contains 'Machine'
    $updatedProcessScope    = $scopes -contains 'Process'

    if ($updatedPersistentScope -and -not $updatedProcessScope) {
        $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
        $userPath    = [Environment]::GetEnvironmentVariable('Path', 'User')

        if ([string]::IsNullOrWhiteSpace($machinePath)) { $machinePath = '' }
        if ([string]::IsNullOrWhiteSpace($userPath))    { $userPath = '' }

        $env:Path = (($machinePath, $userPath) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) -join ';'
    }
}

function Remove-Path {
    [CmdletBinding()]
    param(
        [Alias('p')]
        [string]$Path,

        [Alias('u')]
        [switch]$User,

        [Alias('g')]
        [switch]$Global,

        [Alias('r')]
        [switch]$Process,

        [Alias('s')]
        [ValidateSet('User', 'Machine', 'Process')]
        [string[]]$Setting,

        [Alias('h')]
        [switch]$Help
    )

    $helpText = @'
Remove-Path, remove-path, rp

Removes a directory from PATH.

Usage:
  Remove-Path -p <path> [-u] [-g] [-r] [-s User|Machine|Process]
  Remove-Path -h

Flags:
  -p          Path to remove. Can be relative; will be resolved to a full path.
  -u          Remove from the current user's PATH.
  -g          Remove from the machine PATH.
  -r          Remove from the current process PATH only.
  -s          Explicitly specify User, Machine, or Process.
  -h          Show this help text.

Rules:
  - If no arguments are provided, help is shown.
  - If any scope flag is provided, path is mandatory.
  - Multiple scopes may be used together.
  - If no scope is specified, Machine is used by default.
  - All matching duplicates are removed.
  - Remaining entries are de-duplicated.
'@

    $noArguments =
        -not $PSBoundParameters.ContainsKey('Path')    -and
        -not $PSBoundParameters.ContainsKey('User')    -and
        -not $PSBoundParameters.ContainsKey('Global')  -and
        -not $PSBoundParameters.ContainsKey('Process') -and
        -not $PSBoundParameters.ContainsKey('Setting') -and
        -not $PSBoundParameters.ContainsKey('Help')

    if ($Help -or $noArguments) {
        $helpText
        return
    }

    $scopeRequested =
        $User -or $Global -or $Process -or $PSBoundParameters.ContainsKey('Setting')

    if ($scopeRequested -and [string]::IsNullOrWhiteSpace($Path)) {
        throw "Path is mandatory when any scope flag is used."
    }

    if ([string]::IsNullOrWhiteSpace($Path)) {
        $helpText
        return
    }

    try {
        $resolvedPath = (Resolve-Path -LiteralPath $Path -ErrorAction Stop).Path
    }
    catch {
        throw "Could not resolve path '$Path'. The path must already exist."
    }

    $scopes = New-Object System.Collections.Generic.List[string]

    if ($User)    { [void]$scopes.Add('User') }
    if ($Global)  { [void]$scopes.Add('Machine') }
    if ($Process) { [void]$scopes.Add('Process') }
    if ($Setting) { [void]$scopes.AddRange($Setting) }

    if ($scopes.Count -eq 0) {
        [void]$scopes.Add('Machine')
    }

    $scopes = $scopes | Select-Object -Unique

    foreach ($scope in $scopes) {
        $current = [Environment]::GetEnvironmentVariable('Path', $scope)

        $entries =
            if ([string]::IsNullOrWhiteSpace($current)) {
                @()
            }
            else {
                $current -split ';' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
            }

        $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        $newEntries = New-Object System.Collections.Generic.List[string]
        $removedCount = 0
        $duplicateCount = 0

        foreach ($entry in $entries) {
            $isTarget = [System.StringComparer]::OrdinalIgnoreCase.Equals($entry, $resolvedPath)

            if ($isTarget) {
                $removedCount++
                continue
            }

            if (-not $seen.Add($entry)) {
                $duplicateCount++
                continue
            }

            [void]$newEntries.Add($entry)
        }

        if ($removedCount -eq 0 -and $duplicateCount -eq 0) {
            Write-Host "[$scope] Not found: $resolvedPath"
            continue
        }

        $newValue =
            if ($newEntries.Count -eq 0) {
                ''
            }
            else {
                $newEntries -join ';'
            }

        try {
            [Environment]::SetEnvironmentVariable('Path', $newValue, $scope)
            Write-Host "[$scope] Removed $removedCount matching entr$(if ($removedCount -eq 1) { 'y' } else { 'ies' }): $resolvedPath"
            if ($duplicateCount -gt 0) {
                Write-Host "[$scope] Removed $duplicateCount duplicate entr$(if ($duplicateCount -eq 1) { 'y' } else { 'ies' })."
            }
        }
        catch {
            throw "Failed to update PATH for scope '$scope'. For Machine scope, run PowerShell as Administrator."
        }
    }

    $updatedPersistentScope = $scopes -contains 'User' -or $scopes -contains 'Machine'
    $updatedProcessScope    = $scopes -contains 'Process'

    if ($updatedPersistentScope -and -not $updatedProcessScope) {
        $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
        $userPath    = [Environment]::GetEnvironmentVariable('Path', 'User')

        if ([string]::IsNullOrWhiteSpace($machinePath)) { $machinePath = '' }
        if ([string]::IsNullOrWhiteSpace($userPath))    { $userPath = '' }

        $env:Path = (($machinePath, $userPath) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) -join ';'
    }
}

function Show-Path {
    [CmdletBinding()]
    param(
        [Alias('u')]
        [switch]$User,

        [Alias('g')]
        [switch]$Global,

        [Alias('r')]
        [switch]$Process,

        [Alias('s')]
        [ValidateSet('User', 'Machine', 'Process')]
        [string[]]$Setting,

        [Alias('h')]
        [switch]$Help
    )

    $helpText = @'
Show-Path, show-path, sp

Prints PATH entries line by line for the selected scope(s).

Usage:
  Show-Path [-u] [-g] [-r] [-s User|Machine|Process]
  Show-Path -h

Rules:
  - If no scope is specified, Machine is used by default.
  - Multiple scopes may be used together.
  - Entries equal to current working directory are green.
  - Duplicate entries are red.
'@

    if ($Help) {
        $helpText
        return
    }

    $scopes = New-Object System.Collections.Generic.List[string]

    if ($User)    { [void]$scopes.Add('User') }
    if ($Global)  { [void]$scopes.Add('Machine') }
    if ($Process) { [void]$scopes.Add('Process') }
    if ($Setting) { [void]$scopes.AddRange($Setting) }

    if ($scopes.Count -eq 0) {
        [void]$scopes.Add('Machine')
    }

    $scopes = $scopes | Select-Object -Unique

    $currentDir = (Get-Location).Path

    foreach ($scope in $scopes) {
        $pathValue = [Environment]::GetEnvironmentVariable('Path', $scope)

        Write-Host "[$scope]"

        if ([string]::IsNullOrWhiteSpace($pathValue)) {
            Write-Host "<empty>"
            Write-Host
            continue
        }

        $entries = $pathValue -split ';' | Where-Object { $_ }

        # normalize for duplicate detection
        $normalized = @()
        foreach ($entry in $entries) {
            try {
                $normalized += (Resolve-Path -LiteralPath $entry -ErrorAction Stop).Path
            } catch {
                $normalized += $entry
            }
        }

        # count occurrences
        $counts = @{}
        for ($i = 0; $i -lt $normalized.Count; $i++) {
            $key = $normalized[$i].ToLower()
            if ($counts.ContainsKey($key)) {
                $counts[$key]++
            } else {
                $counts[$key] = 1
            }
        }

        for ($i = 0; $i -lt $entries.Count; $i++) {
            $entry = $entries[$i]
            $norm  = $normalized[$i]
            $key   = $norm.ToLower()

            $isDuplicate = $counts[$key] -gt 1
            $isCwd = [string]::Equals($norm, $currentDir, [System.StringComparison]::OrdinalIgnoreCase)

            if ($isDuplicate) {
                Write-Host $entry -ForegroundColor Red
            }
            elseif ($isCwd) {
                Write-Host $entry -ForegroundColor Green
            }
            else {
                Write-Host $entry
            }
        }

        Write-Host
    }
}

Set-Alias ap Add-Path
Set-Alias Delete-Path Remove-Path
Set-Alias Print-Path Show-Path