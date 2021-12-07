Import-Module .\rac

Param (
    [string]$ClusterName,
    [string]$InfobaseName,
    [string]$InfobaseUser,
    [string]$InfobasePassword,
    [string]$AccessCode
)

$rac = Get-Rac
$cluster = Get-ClusterByName -Rac $rac -ClusterName $ClusterName
$infobase = Get-InfobaseByName -Rac $rac -ClusterUUID $cluster.cluster -InfobaseName $InfobaseName

Block-Connections -Rac $rac -ClusterUUID $cluster.cluster -InfobaseUUID $infobase.infobase -User $InfobaseUser -Password $InfobasePassword -AccessCode $AccessCode
Close-Sessions -Rac $rac -ClusterUUID $cluster.cluster -InfobaseUUID $infobase.infobase