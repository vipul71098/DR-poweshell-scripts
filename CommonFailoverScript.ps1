# Function to perform failover with Elastic Pool
function Failover-WithElasticPool {
    param (
        [string]$ResourceGroupName,
        [string]$ServerName,
        [string]$DatabaseName
    )

    # Ensure Azure CLI is authenticated
    $account = az account show --output json | ConvertFrom-Json
    if ($account -eq $null -or $account.state -ne "Enabled") {
        Write-Host "Azure CLI not authenticated or context is invalid. Logging in..."
        az login --service-principal -u $env:AZURE_CLIENT_ID -p $env:AZURE_CLIENT_SECRET --tenant $env:AZURE_TENANT_ID
    }

    # Set the subscription context
    $subscriptionId = $account.id
    az account set --subscription $subscriptionId

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

    # Ensure Azure CLI is authenticated
    $account = az account show --output json | ConvertFrom-Json
    if ($account -eq $null -or $account.state -ne "Enabled") {
        Write-Host "Azure CLI not authenticated or context is invalid. Logging in..."
        az login --service-principal -u $env:AZURE_CLIENT_ID -p $env:AZURE_CLIENT_SECRET --tenant $env:AZURE_TENANT_ID
    }

    # Set the subscription context
    $subscriptionId = $account.id
    az account set --subscription $subscriptionId

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
if ($UseElasticPool) {
    Failover-WithElasticPool -ResourceGroupName $ResourceGroupName -ServerName $ServerName -DatabaseName $DatabaseName
} else {
    Failover-WithoutElasticPool -ResourceGroupName $ResourceGroupName -ServerName $ServerName -FailoverGroupName $FailoverGroupName
}


# param (
#     [string]$ResourceGroupName = "",
#     [string]$DatabaseName = "",
#     [string]$ServerName = "",
#     [string]$FailoverGroupName = "",
#     [bool]$UseElasticPool = $false
# )

# # Function to perform failover with Elastic Pool
# function Failover-WithElasticPool {
#     param (
#         [string]$ResourceGroupName,
#         [string]$ServerName,
#         [string]$DatabaseName
#     )

#     # Ensure Azure CLI is authenticated
#     if (-not (az account show)) {
#         Write-Host "Azure CLI not authenticated. Logging in..."
#         az login --service-principal -u $env:AZURE_CLIENT_ID -p $env:AZURE_CLIENT_SECRET --tenant $env:AZURE_TENANT_ID
#     }

#     # Set the subscription context
#     $subscriptionId = (az account show --query id --output tsv)
#     az account set --subscription $subscriptionId

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

#     # Ensure Azure CLI is authenticated
#     if (-not (az account show)) {
#         Write-Host "Azure CLI not authenticated. Logging in..."
#         az login --service-principal -u $env:AZURE_CLIENT_ID -p $env:AZURE_CLIENT_SECRET --tenant $env:AZURE_TENANT_ID
#     }

#     # Set the subscription context
#     $subscriptionId = (az account show --query id --output tsv)
#     az account set --subscription $subscriptionId

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
# if ($UseElasticPool) {
#     Failover-WithElasticPool -ResourceGroupName $ResourceGroupName -ServerName $ServerName -DatabaseName $DatabaseName
# } else {
#     Failover-WithoutElasticPool -ResourceGroupName $ResourceGroupName -ServerName $ServerName -FailoverGroupName $FailoverGroupName
# }
