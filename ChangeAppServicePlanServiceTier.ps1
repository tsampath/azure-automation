Param
(
  [Parameter (Mandatory= $true)]
  [String] $resourceGroupName = "<ResourceGroupName>",

  [Parameter (Mandatory= $true)]
  [String] $appServicePlanName = "<AppServicePlanName>",

  [Parameter (Mandatory= $true)]
  [String] $nextTier = "F1",

  [Parameter (Mandatory= $false)]
  [String] $maxAllowedTier = "B2"
)

$connectionName = "<AzureRunAsConnectionName>"

# Adjust tier levels and their order to fit your needs.
$tierLevels = @("F1", "D1", "B1", "B2", "B3", "S1", "S2", "S3", "P1", "P2", "P3")
$tierConfigs = @{
    F1=@("Free","");
    D1=@("Shared","");
    B1=@("Basic","Small");
    B2=@("Basic","Medium");
    B3=@("Basic","Large");
    S1=@("Standard","Small");
    S2=@("Standard","Medium");
    S3=@("Standard","Large");
    P1=@("Premium","Small");
    P2=@("Premium","Medium");
    P3=@("Premium","Large");
}

Function IndexOf {
    param (
        [array]$Array, [string]$Item
    )

    return (0..($Array.Count-1)) | Where-Object {$array[$_] -eq $Item}
}
Write-Output "Start"

try {
    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName
    Add-AzureRmAccount -ServicePrincipal -TenantId $servicePrincipalConnection.TenantId -ApplicationId $servicePrincipalConnection.ApplicationId -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint

    $currentPlan = Get-AzureRmAppServicePlan -ResourceGroupName $resourceGroupName -Name $appServicePlanName
    $currentTier = $currentPlan.Sku.Name
    Write-Output "Current tier: $currentTier"

    $currentTierIndex = IndexOf -Array $tierLevels -Item $currentTier
    Write-Output "Current tier index: $currentTierIndex"
    # $indexOfMaxAllowedTier = IndexOf -Array $tierLevels -Item $maxAllowedTier
    # $nextTier = $tierLevels[$currentTierIndex + 1]

    # if ($currentTierIndex -lt $indexOfMaxAllowedTier) {

        $targetTierConfig = $tierConfigs[$nextTier]
        $targetTier = $targetTierConfig[0]
        $targetWorkerSize = $targetTierConfig[1]
        Write-Output "Scaling $currentTier to $targetTier"
		Write-Output "TargetWorkerSize $targetWorkerSize"

        if ($targetWorkerSize -eq "") {
            Set-AzureRmAppServicePlan -ResourceGroupName $resourceGroupName -Name $appServicePlanName -Tier $targetTier
        } else {
            Set-AzureRmAppServicePlan -ResourceGroupName $resourceGroupName -Name $appServicePlanName -Tier $targetTier -WorkerSize $targetWorkerSize
        }
    # } else {
    #    $ErrorMessage = "Cannot scale up to $nextTier. CuurentTier $currentTier is the higest allowed."
    #    throw $ErrorMessage
    # }
}

catch {
    if (!$servicePrincipalConnection) {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage 
    } 
    else { 
        Write-Error -Message $_.Exception 
        throw $_.Exception
    }
}
