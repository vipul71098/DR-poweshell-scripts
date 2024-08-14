param (
    [string]$ResourceGroupName = "",
    [string]$DatabaseName = "",
    [string]$ServerName = "",
    [string]$FailoverGroupName = "",
    [bool]$UseElasticPool = $false
)

# Function to perform failover with Elastic Pool
function Failover-WithElasticPool {
    param (
        [string]$ResourceGroupName,
        [string]$ServerName,
        [string]$DatabaseName
    )

    Write-Host "Starting Failover-WithElasticPool function..."

    # Login to Azure using Service Principal credentials
    if (-not (Get-AzContext)) {
        Write-Host "Authenticating with Azure..."
        $tenantId = $env:AZURE_TENANT_ID
        $clientId = $env:AZURE_CLIENT_ID
        $clientSecret = $env:AZURE_CLIENT_SECRET

        $secureClientSecret = ConvertTo-SecureString $clientSecret -AsPlainText -Force
        $psCredential = New-Object Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmServicePrincipalCredential($clientId, $secureClientSecret, $tenantId)
        
        Connect-AzAccount -ServicePrincipal -Credential $psCredential -Tenant $tenantId
        Write-Host "Authenticated successfully."
    }

    # Parameters for the failover
    $parameters = @{
        ResourceGroupName = $ResourceGroupName
        ServerName = $ServerName
        DatabaseName = $DatabaseName
        PartnerResourceGroupName = $ResourceGroupName
    }

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

    Write-Host "Starting Failover-WithoutElasticPool function..."

    # Login to Azure using Service Principal credentials
    if (-not (Get-AzContext)) {
        Write-Host "Authenticating with Azure..."
        $tenantId = $env:AZURE_TENANT_ID
        $clientId = $env:AZURE_CLIENT_ID
        $clientSecret = $env:AZURE_CLIENT_SECRET

        $secureClientSecret = ConvertTo-SecureString $clientSecret -AsPlainText -Force
        $psCredential = New-Object Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmServicePrincipalCredential($clientId, $secureClientSecret, $tenantId)
        
        Connect-AzAccount -ServicePrincipal -Credential $psCredential -Tenant $tenantId
        Write-Host "Authenticated successfully."
    }

    try {
        Write-Host "Failing over failover group to the secondary..."
        Switch-AzSqlDatabaseFailoverGroup `
           -ResourceGroupName $ResourceGroupName `
           -ServerName $ServerName `
           -FailoverGroupName $FailoverGroupName -ErrorAction Stop
        Write-Host "Failed failover group successfully to" $ServerName 

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

#     # Login to Azure using Azure CLI authentication
#     if (-not (Get-AzContext)) {
#         Connect-AzAccount -Identity
#     }

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

#     # Login to Azure using Azure CLI authentication
#     if (-not (Get-AzContext)) {
#         Connect-AzAccount -Identity
#     }

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



# # param (
# #     [string]$ResourceGroupName = "",
# #     [string]$DatabaseName = "",
# #     [string]$ServerName = "",
# #     [string]$FailoverGroupName = "",
# #     [bool]$UseElasticPool = $false
# # )

# # # Function to perform failover with Elastic Pool
# # function Failover-WithElasticPool {
# #     param (
# #         [string]$ResourceGroupName,
# #         [string]$ServerName,
# #         [string]$DatabaseName
# #     )
    
# #     # Login to Azure
# #     Connect-AzAccount

# #     # Parameters for the failover
# #     $parameters = @{
# #         ResourceGroupName = $ResourceGroupName
# #         ServerName = $ServerName
# #         DatabaseName = $DatabaseName
# #         PartnerResourceGroupName = $ResourceGroupName
# #     }

# #     # Initiate the failover
# #     Write-Host "Initiating failover for database $DatabaseName from server $ServerName..."
# #     try {
# #         Set-AzSqlDatabaseSecondary @parameters -Failover
# #         Write-Host "Failover initiated successfully. Please wait while the failover process completes..."
# #     } catch {
# #         Write-Host "Error initiating failover: $($_.Exception.Message)"
# #     }

# #     # Wait for the failover to complete
# #     Start-Sleep -Seconds 30  # Increased sleep duration to account for propagation time

# #     Write-Host "Failover process completed. Please verify the status in the Azure portal."
# # }

# # # Function to perform failover without Elastic Pool
# # function Failover-WithoutElasticPool {
# #     param (
# #         [string]$ResourceGroupName,
# #         [string]$ServerName,
# #         [string]$FailoverGroupName
# #     )
    
# #     # Login to Azure
# #     Connect-AzAccount

# #     try {
# #         # Failover to secondary server
# #         Write-Host "Failing over failover group to the secondary..."
# #         Switch-AzSqlDatabaseFailoverGroup `
# #            -ResourceGroupName $ResourceGroupName `
# #            -ServerName $ServerName `
# #            -FailoverGroupName $FailoverGroupName -ErrorAction Stop
# #         Write-Host "Failed failover group successfully to" $ServerName 

# #         # Confirm the secondary server is now primary
# #         Write-Host "Confirming the secondary server is now primary..."
# #         $failoverGroup = Get-AzSqlDatabaseFailoverGroup `
# #            -FailoverGroupName $FailoverGroupName `
# #            -ResourceGroupName $ResourceGroupName `
# #            -ServerName $ServerName -ErrorAction Stop
# #         Write-Host "The replication role of the failover group is:" $failoverGroup.ReplicationRole
# #     } catch {
# #         Write-Error "An error occurred: $_"
# #     }
# # }

# # # Main Script
# # if ($UseElasticPool) {
# #     Failover-WithElasticPool -ResourceGroupName $ResourceGroupName -ServerName $ServerName -DatabaseName $DatabaseName
# # } else {
# #     Failover-WithoutElasticPool -ResourceGroupName $ResourceGroupName -ServerName $ServerName -FailoverGroupName $FailoverGroupName
# # }
