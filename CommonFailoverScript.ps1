param (
    [string]$ResourceGroupName = "",
    [string]$DatabaseName = "",
    [string]$ServerName = "",
    [string]$FailoverGroupName = "",
    [bool]$UseElasticPool = $false
)

function Failover-WithElasticPool {
    param (
        [string]$ResourceGroupName,
        [string]$ServerName,
        [string]$DatabaseName
    )

    Write-Host "Starting Failover-WithElasticPool function..."
    Write-Host "Authenticating with Azure..."

    if (-not (Get-AzContext)) {
        $tenantId = $env:AZURE_TENANT_ID
        $clientId = $env:AZURE_CLIENT_ID
        $clientSecret = $env:AZURE_CLIENT_SECRET

        $secureClientSecret = ConvertTo-SecureString $clientSecret -AsPlainText -Force
        $psCredential = New-Object Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmServicePrincipalCredential($clientId, $secureClientSecret, $tenantId)
        
        Connect-AzAccount -ServicePrincipal -Credential $psCredential -Tenant $tenantId
        Write-Host "Authenticated successfully."
    }

    $parameters = @{
        ResourceGroupName = $ResourceGroupName
        ServerName = $ServerName
        DatabaseName = $DatabaseName
        PartnerResourceGroupName = $ResourceGroupName
    }

    Write-Host "Initiating failover for database $DatabaseName from server $ServerName..."
    try {
        Set-AzSqlDatabaseSecondary @parameters -Failover -Verbose
        Write-Host "Failover initiated successfully. Please wait while the failover process completes..."
    } catch {
        Write-Host "Error initiating failover: $($_.Exception.Message)"
    }

    Start-Sleep -Seconds 30
    Write-Host "Failover process completed. Please verify the status in the Azure portal."
}

function Failover-WithoutElasticPool {
    param (
        [string]$ResourceGroupName,
        [string]$ServerName,
        [string]$FailoverGroupName
    )

    Write-Host "Starting Failover-WithoutElasticPool function..."

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
           -FailoverGroupName $FailoverGroupName -Verbose -ErrorAction Stop
        Write-Host "Failed failover group successfully to" $ServerName 

        Write-Host "Confirming the secondary server is now primary..."
        $failoverGroup = Get-AzSqlDatabaseFailoverGroup `
           -FailoverGroupName $FailoverGroupName `
           -ResourceGroupName $ResourceGroupName `
           -ServerName $ServerName -Verbose -ErrorAction Stop
        Write-Host "The replication role of the failover group is:" $failoverGroup.ReplicationRole
    } catch {
        Write-Error "An error occurred: $_"
    }
}
