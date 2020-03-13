param(
    [parameter(Position=0,Mandatory=$true)][string]$storageAccount,
    [parameter(Position=1,Mandatory=$true)][string]$storageAccessKey 
)

function Get-AzTableHeader() {
    [CmdletBinding()] param(
        [string] $resource
    )

    $url = "https://$storageAccount.table.core.windows.net/$resource"
    $time = (Get-Date).ToUniversalTime().toString('R')
    $stringToSign = "$time`n/$storageAccount/$resource"
    $hmacsha = New-Object System.Security.Cryptography.HMACSHA256
    $hmacsha.key = [Convert]::FromBase64String($storageAccessKey)
    $signature = [Convert]::ToBase64String($hmacsha.ComputeHash([Text.Encoding]::UTF8.GetBytes($stringToSign)))
    return @{
        'x-ms-date'      = $time
        Authorization    = "SharedKeyLite " + $storageAccount + ":" + $signature
        "x-ms-version"   = "2018-03-28"
        Accept           = "application/json;odata=minimalmetadata"
        'Accept-Charset' = "UTF-8"
        'Content-type'   = "application/json"
    }
}

function Get-AzTableEntries() {
    [CmdletBinding()] param(
        [string] $table,
        [string] $select = $null,
        [string] $filter = $null
    )

    $statistincs = $null
    $url = "https://$storageAccount.table.core.windows.net/$table" 
    if ([String]::IsNullOrEmpty($select) -eq $false) {
        $url += '?$select=' + $select
    }
    if ([String]::IsNullOrEmpty($filter) -eq $false) {
        if ([String]::IsNullOrEmpty($select) -eq $false) {
            $url += '&'
        }
        else {
            $url += '?'
        }
        $url += '$filter=' + $filter
    }

    Write-Host $url
    $headers = Get-AzTableHeader -resource $table

    $baseUrl = $url

    $totalItems = 0
    $results = @()
    Write-Host -NoNewline "Invoking request..."
    do {
        $item = Invoke-WebRequest -Method GET -Uri $url -Headers $headers
      
        $nextPartition = $item.Headers.'x-ms-continuation-NextPartitionKey'
        $nextRowKey = $item.Headers.'x-ms-continuation-NextRowKey'

        $url = $baseUrl
        if ([String]::IsNullOrEmpty($nextPartition) -eq $false) {
            if ($baseUrl.IndexOf("?") -gt -1) {
                $url = $url + "&"   
            }
            else {
                $url = $url + "?"   
            }
            $url = $url + "NextPartitionKey=$($nextPartition)"
        }

        if ([String]::IsNullOrEmpty($nextRowKey) -eq $false) {
            if ($url.IndexOf("?") -gt -1) {
                $url = $url + "&"   
            }
            else {
                $url = $url + "?"   
            }
            $url = $url + "NextRowKey=$($nextRowKey)"
        }

        $content = $item.Content | ConvertFrom-Json
        $results += $content.value
        $statistincs = $results | Measure-Object
    }
    while ([String]::IsNullOrEmpty($nextPartition) -eq $false -or [String]::IsNullOrEmpty($nextRowKey) -eq $false)
    Write-Host
    Write-Host "$($statistincs.Count) items found"
    
    return $results
}
export-modulemember -function Get-AzTableEntries

function Get-AzTableEntry {
    [CmdletBinding()] param(
        [string] $table,
        [string] $partitionKey = $null,
        [string] $rowKey = $null
    )
    $resource = "$table(PartitionKey='$partitionKey',RowKey='$rowKey')"
    $headers = Get-AzTableHeader -resource $resource
    return (Invoke-RestMethod -Method GET -Uri ("https://$storageAccount.table.core.windows.net/$resource") -Headers $headers)
}
export-modulemember -function Get-AzTableEntry

function Merge-AzTableEntry {
    [CmdletBinding()] param(
        [string] $table,
        [string] $partitionKey = $null,
        [string] $rowKey = $null,
        [object] $entity = $null
    )
    $body = $entity | ConvertTo-Json
    $body = [System.Text.Encoding]::UTF8.GetBytes($body) 
    $resource = "$table(PartitionKey='$partitionKey',RowKey='$rowKey')"
    $headers = Get-AzTableHeader -resource $resource
    return Invoke-RestMethod -Method MERGE -Uri ("https://$storageAccount.table.core.windows.net/$resource") -Headers $headers -Body $body
}
export-modulemember -function Merge-AzTableEntry

function Add-AzTableEntry {
    [CmdletBinding()] param(
        [string] $table,
        [string] $partitionKey = $null,
        [string] $rowKey = $null,
        [object] $entity = $null
    )
    $body = $entity | ConvertTo-Json
    $body = [System.Text.Encoding]::UTF8.GetBytes($body) 
    $resource = "$table(PartitionKey='$partitionKey',RowKey='$rowKey')"
    $headers = Get-AzTableHeader -resource $resource
    return Invoke-RestMethod -Method PUT -Uri ("https://$storageAccount.table.core.windows.net/$resource") -Headers $headers -Body $body
}
export-modulemember -function Add-AzTableEntry

function Remove-AzTableEntry {
    [CmdletBinding()] param(
            [string] $table,
            [string] $partitionKey = $null,
            [string] $rowKey = $null
    )
    $resource = "$table(PartitionKey='$PartitionKey',RowKey='$Rowkey')"
    $headers = Get-AzTableHeader -resource $resource
    $headers.Add("If-Match", "*")
    $noResults = Invoke-RestMethod -Method Delete -Uri ("https://$storageAccount.table.core.windows.net/$resource") -Headers $headers
}
export-modulemember -function Remove-AzTableEntry

function New-AzTable {
    [CmdletBinding()] param(
        [string] $table
    )
    $resource = "tables"
    $headers = Get-AzTableHeader -resource $resource
    $body = @{
        "TableName" = $table
    }
    return Invoke-RestMethod -Method POST -Uri ("https://$storageAccount.table.core.windows.net/tables") -Headers $headers -Body ($body | convertto-json)
}
export-modulemember -function New-AzTable

function Remove-AzTable {
    [CmdletBinding()] param(
        [string] $table
    )
    $resource = "tables('$($table)')"
    $headers = Get-AzTableHeader -resource $resource
    $body = @{
        "TableName" = $table
    }
    return Invoke-RestMethod -Method DELETE -Uri ("https://$storageAccount.table.core.windows.net/$resource") -Headers $headers -Body ($body | convertto-json)
}
export-modulemember -function Remove-AzTable
