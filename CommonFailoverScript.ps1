param (
    [switch]$useElasticPool,
    [string]$serverName,
    [string]$databaseName,
    [string]$failoverGroupName,
    [string]$resourceGroupName,
    [string]$tenantId,
    [string]$appId,
    [string]$password
)

# Function to perform failover with Elastic Pool
function Failover-WithElasticPool {
    param (
        [string]$ResourceGroupName,
        [string]$ServerName,
        [string]$DatabaseName
    )
    
    # Login to Azure using Service Principal
    $psCredential = New-Object Microsoft.Azure.Commands.Common.Authentication.Abstractions.ServicePrincipalToken($appId, $password, $tenantId)
    Connect-AzAccount -ServicePrincipal -Credential $psCredential -Tenant $tenantId

    # Parameters for the failover
    $parameters = @{
        ResourceGroupName = $ResourceGroupName
        ServerName = $ServerName
        DatabaseName = $DatabaseName
        PartnerResourceGroupName = $ResourceGroupName
    }

    # Initiate the failover
    Write-Host "Initiating failover for database $DatabaseName from server $ServerName..."
    try {
        Set-AzSqlDatabaseSecondary @parameters -Failover
        Write-Host "Failover initiated successfully. Please wait while the failover process completes..."
    } catch {
        Write-Host "Error initiating failover: $($_.Exception.Message)"
    }

    # Wait for the failover to complete
    Start-Sleep -Seconds 30  # Increased sleep duration to account for propagation time

    Write-Host "Failover process completed. Please verify the status in the Azure portal."
}

# Function to perform failover without Elastic Pool
function Failover-WithoutElasticPool {
    param (
        [string]$ResourceGroupName,
        [string]$ServerName,
        [string]$FailoverGroupName
    )
    
    # Login to Azure using Service Principal
    $psCredential = New-Object Microsoft.Azure.Commands.Common.Authentication.Abstractions.ServicePrincipalToken($appId, $password, $tenantId)
    Connect-AzAccount -ServicePrincipal -Credential $psCredential -Tenant $tenantId

    try {
        # Failover to secondary server
        Write-Host "Failing over failover group to the secondary..."
        Switch-AzSqlDatabaseFailoverGroup `
           -ResourceGroupName $ResourceGroupName `
           -ServerName $ServerName `
           -FailoverGroupName $FailoverGroupName -ErrorAction Stop
        Write-Host "Failed failover group successfully to" $ServerName 

        # Confirm the secondary server is now primary
        Write-Host "Confirming the secondary server is now primary..."
        $failoverGroup = Get-AzSqlDatabaseFailoverGroup `
           -FailoverGroupName $FailoverGroupName `
           -ResourceGroupName $ResourceGroupName `
           -ServerName $ServerName -ErrorAction Stop
        Write-Host "The replication role of the failover group is:" $failoverGroup.ReplicationRole
    } catch {
        Write-Error "An error occurred: $_"
    }
}

# Main Script
if ($useElasticPool) {
    Failover-WithElasticPool -ResourceGroupName $resourceGroupName -ServerName $serverName -DatabaseName $databaseName
} else {
    Failover-WithoutElasticPool -ResourceGroupName $resourceGroupName -ServerName $serverName -FailoverGroupName $failoverGroupName
}

# param (
#     [switch]$useElasticPool,
#     [string]$serverName,
#     [string]$databaseName,
#     [string]$failoverGroupName,
#     [string]$resourceGroupName
# )

# # Function to perform failover with Elastic Pool
# function Failover-WithElasticPool {
#     param (
#         [string]$ResourceGroupName,
#         [string]$ServerName,
#         [string]$DatabaseName
#     )
    
#     # Login to Azure
#     Connect-AzAccount

#     # Parameters for the failover
#     $parameters = @{
#         ResourceGroupName = $ResourceGroupName
#         ServerName = $ServerName
#         DatabaseName = $DatabaseName
#         PartnerResourceGroupName = $ResourceGroupName
#     }

#     # Initiate the failover
#     Write-Host "Initiating failover for database $DatabaseName from server $ServerName..."
#     try {
#         Set-AzSqlDatabaseSecondary @parameters -Failover
#         Write-Host "Failover initiated successfully. Please wait while the failover process completes..."
#     } catch {
#         Write-Host "Error initiating failover: $($_.Exception.Message)"
#     }

#     # Wait for the failover to complete
#     Start-Sleep -Seconds 30  # Increased sleep duration to account for propagation time

#     Write-Host "Failover process completed. Please verify the status in the Azure portal."
# }

# # Function to perform failover without Elastic Pool
# function Failover-WithoutElasticPool {
#     param (
#         [string]$ResourceGroupName,
#         [string]$ServerName,
#         [string]$FailoverGroupName
#     )
    
#     # Login to Azure
#     Connect-AzAccount

#     try {
#         # Failover to secondary server
#         Write-Host "Failing over failover group to the secondary..."
#         Switch-AzSqlDatabaseFailoverGroup `
#            -ResourceGroupName $ResourceGroupName `
#            -ServerName $ServerName `
#            -FailoverGroupName $FailoverGroupName -ErrorAction Stop
#         Write-Host "Failed failover group successfully to" $ServerName 

#         # Confirm the secondary server is now primary
#         Write-Host "Confirming the secondary server is now primary..."
#         $failoverGroup = Get-AzSqlDatabaseFailoverGroup `
#            -FailoverGroupName $FailoverGroupName `
#            -ResourceGroupName $ResourceGroupName `
#            -ServerName $ServerName -ErrorAction Stop
#         Write-Host "The replication role of the failover group is:" $failoverGroup.ReplicationRole
#     } catch {
#         Write-Error "An error occurred: $_"
#     }
# }

# # Main Script
# if ($useElasticPool) {
#     Failover-WithElasticPool -ResourceGroupName $resourceGroupName -ServerName $serverName -DatabaseName $databaseName
# } else {
#     Failover-WithoutElasticPool -ResourceGroupName $resourceGroupName -ServerName $serverName -FailoverGroupName $failoverGroupName
# }
