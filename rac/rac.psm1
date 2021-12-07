function Get-Rac {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false, HelpMessage="If the version is not specified, so it'll return the newest version of the rac.exe")] 
        [string]$Version = "8\.3\..*"
    )

    $path = ""

    $platforms = Get-ChildItem "C:\Program Files\1cv8" | Where-Object { $_.Name -match $Version } | Sort-Object { $_.Name } -Descending

    if ($platforms.Length -eq 0) {
        throw "Couldn't get path to the rac.exe"
    }
    else {
        $path = $platforms[0].FullName + "\bin\rac.exe"
    }

    if ($path -eq [string]::Empty -or !(Test-Path $path)) {
        throw "Couldn't find rac.exe file"
    } else {
        return $path
    }
}

function Parse-Output {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [array]$Output
    )

    $resultArray = @()

    $currentObject = @{}

    foreach ($line in $Output) {
        if ($line -eq "") {
            $resultArray += $currentObject
            $currentObject = @{}
            continue
        }
        else {
            $kv = $line.Split(":")
            $key = $kv[0].Trim()
            $value = $kv[1].Trim()
            $currentObject[$key] = $value
        }
    }

    return $resultArray
}

function Start-Command {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Rac,
        [Parameter(Mandatory=$true)]
        [string]$Command,
        [Parameter(Mandatory=$false)]
        [bool]$ParseOutput = $true
    )

    $output = cmd /c """$Rac"" $Command"

    if ($ParseOutput) {
        return Parse-Output -Output $output
    }
    else {
        return $output
    }
}

function Get-Clusters {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Rac
    )

    return Start-Command $Rac "cluster list"
}

function Get-ClusterByName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Rac,
        [Parameter(Mandatory=$true)]
        [string]$ClusterName
    )
    
    return Get-Clusters $Rac | Where-Object { $_.name -match $ClusterName }
}

function Get-Infobases {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Rac,
        [Parameter(Mandatory=$true)]
        [string]$ClusterUUID
    )
    return Start-Command $Rac "infobase --cluster=$ClusterUUID summary list"
}

function Get-InfobaseByName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Rac,
        [Parameter(Mandatory=$true)]
        [string]$ClusterUUID,
        [Parameter(Mandatory=$true)]
        [string]$InfobaseName
    )
    return Get-Infobases $Rac $ClusterUUID | Where-Object { $_.name -match $InfobaseName }
}

function Get-Sessions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Rac,
        [Parameter(Mandatory=$true)]
        [string]$ClusterUUID
    )
    return Start-Command $Rac "session --cluster=$ClusterUUID list"
}

function Get-Sessions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Rac,
        [Parameter(Mandatory=$true)]
        [string]$ClusterUUID,
        [Parameter(Mandatory=$true)]
        [string]$InfobaseUUID
    )
    return Start-Command $Rac "session --cluster=$ClusterUUID list --infobase=$InfobaseUUID"
}

function Close-Session {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Rac,
        [Parameter(Mandatory=$true)]
        [string]$ClusterUUID,
        [Parameter(Mandatory=$true)]
        [string]$SessionUUID
    )

    Start-Command $Rac "session --cluster=$ClusterUUID terminate --session=$SessionUUID" $false
}

function Close-Sessions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Rac,
        [Parameter(Mandatory=$true)]
        [string]$ClusterUUID
    )

    $sessions = Get-Sessions $Rac $ClusterUUID

    foreach($session in $sessions)
    {
        Close-Session $Rac $ClusterUUID $session.session
    }
}

function Close-Sessions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Rac,
        [Parameter(Mandatory=$true)]
        [string]$ClusterUUID,
        [Parameter(Mandatory=$true)]
        [string]$InfobaseUUID
    )

    $sessions = Get-Sessions $Rac $ClusterUUID $InfobaseUUID

    foreach($session in $sessions)
    {
        Close-Session $Rac $ClusterUUID $session.session
    }
}

function Block-Connections {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Rac,
        [Parameter(Mandatory=$true)]
        [string]$ClusterUUID,
        [Parameter(Mandatory=$true)]
        [string]$InfobaseUUID,
        [Parameter(Mandatory=$true)]
        [string]$User,
        [Parameter(Mandatory=$true)]
        [string]$Password,
        [Parameter(Mandatory=$true)]
        [string]$AccessCode
    )

    $command =
    "infobase " +
    "--cluster=$ClusterUUID " +
    "update " +
    "--infobase=$InfobaseUUID " +
    "--infobase-user=""$User"" " +
    "--infobase-pwd=""$Password"" " +
    "--permission-code=""$AccessCode"" " +
    "--sessions-deny=on " +
    "--scheduled-jobs-deny=on"

    Start-Command $Rac $command $false
}

function Unblock-Connections {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Rac,
        [Parameter(Mandatory=$true)]
        [string]$ClusterUUID,
        [Parameter(Mandatory=$true)]
        [string]$InfobaseUUID,
        [Parameter(Mandatory=$true)]
        [string]$User,
        [Parameter(Mandatory=$true)]
        [string]$Password
    )

    $command =
    "infobase " +
    "--cluster=$ClusterUUID " +
    "update " +
    "--infobase=$InfobaseUUID " +
    "--infobase-user=""$User"" " +
    "--infobase-pwd=""$Password"" " +
    "--sessions-deny=off " +
    "--scheduled-jobs-deny=off"

    Start-Command $Rac $command $false
}