

# Define variables
param (
    [bool]$useElasticPool = $false, # Set this to $true if you want to use Elastic Pool failover, otherwise set it to $false
    [string]$resourceGroupName = "",
    [string]$databaseName = "",
    [string]$serverName = "",
    [string]$failoverGroupName = ""
)

# Log parameter values for debugging
Write-Host "useElasticPool: $useElasticPool"
Write-Host "resourceGroupName: $resourceGroupName"
Write-Host "databaseName: $databaseName"
Write-Host "serverName: $serverName"
Write-Host "failoverGroupName: $failoverGroupName"

# Function to perform failover with Elastic Pool
function Failover-WithElasticPool {
    param (
        [string]$ResourceGroupName,
        [string]$ServerName,
        [string]$DatabaseName
    )
    
    # Login to Azure
     #Connect-AzAccount -ServicePrincipal -Tenant $env:AZURE_TENANT_ID -ApplicationId $env:AZURE_CLIENT_ID -Credential (New-Object PSCredential($env:AZURE_CLIENT_ID, (ConvertTo-SecureString $env:AZURE_CLIENT_SECRET -AsPlainText -Force)))
     #Connect-AzAccount -ServicePrincipal -Tenant $env:AZURE_TENANT_ID -ApplicationId $env:AZURE_CLIENT_ID -CertificateThumbprint $null -Credential (New-Object PSCredential($env:AZURE_CLIENT_ID, (ConvertTo-SecureString $env:AZURE_CLIENT_SECRET -AsPlainText -Force)))


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
    
    # Login to Azure
    #Connect-AzAccount -ServicePrincipal -Tenant $env:AZURE_TENANT_ID -ApplicationId $env:AZURE_CLIENT_ID -Credential (New-Object PSCredential($env:AZURE_CLIENT_ID, (ConvertTo-SecureString $env:AZURE_CLIENT_SECRET -AsPlainText -Force)))
    #Connect-AzAccount -ServicePrincipal -Tenant $env:AZURE_TENANT_ID -ApplicationId $env:AZURE_CLIENT_ID -CertificateThumbprint $null -Credential (New-Object PSCredential($env:AZURE_CLIENT_ID, (ConvertTo-SecureString $env:AZURE_CLIENT_SECRET -AsPlainText -Force)))

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

$context = Get-AzContext
if (-not $context) {
    Write-Error "No Azure context found. Please ensure you are logged in and have set the subscription context."
    exit 1
}

# Set Azure context if not already set
if ($context.Subscription.Id -ne $env:AZURE_SUBSCRIPTION_ID) {
    Set-AzContext -SubscriptionId $env:AZURE_SUBSCRIPTION_ID
}

# Main Script
if ($useElasticPool) {
    Failover-WithElasticPool -ResourceGroupName $resourceGroupName -ServerName $serverName -DatabaseName $databaseName
} else {
    Failover-WithoutElasticPool -ResourceGroupName $resourceGroupName -ServerName $serverName -FailoverGroupName $failoverGroupName
}

