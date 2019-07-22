# Azure Table Storage CRUD operations with PowerShell
This PowerShell module encapsulates basic CRUD operations against [Azure Table Storage](https://azure.microsoft.com/en-us/services/storage/tables/). The module uses the REST API to perform these activities.
This module has been used in several projects to store and manipulate data in automation scripts against Azure Tables.

# Usage
- Get the AZTableModule.psm1 and store it to your desired location
- Get your Azure Storage name and key. You will need it in the script

# Examples

**initializing the module**<br />
$storage = "addYourStorageNameHere"<br />
$key = "addYourStorageSecretKeyHere"<br /><br />

Import-Module AZTableModule.psm1 -ArgumentList $storage, $key<br /><br />

**creating a new table**<br />
New-AzTable "sampletable"<br /><br />

**add a new entry to your table**<br />
- Dates must be older or equal than "1901-01-01"
- Replaces the entry if the unique key and partitionkey matches

$birthDate = (Get-date -date "1983-01-02")<br />
$patrick = @{<br />
    PartitionKey = 'yourPartitionName'<br />
    RowKey = 'yourUniqueRowKeyPatrick'<br />
    "birthDate@odata.type"="Edm.DateTime"<br />
    birthDate = $birthDate.toString("yyyy-MM-ddT00:00:00.000Z")<br />
    name = "Patrick"<br />
    lastname = "Lamber"<br />
}<br />
Add-AzTableEntry -table "sampletable" -partitionKey $patrick.PartitionKey -rowKey $patrick.RowKey -entity $patrick<br /><br />

**create a new entry or merge it with an existing one**<br />
$birthDate = (Get-date -date "1986-10-19")<br />
$rene = @{<br />
    PartitionKey = 'yourPartitionName'<br />
    RowKey = 'yourUniqueRowKeyRene'<br />
    "birthDate@odata.type"="Edm.DateTime"<br />
    birthDate = $birthDate.toString("yyyy-MM-ddT00:00:00.000Z")<br />
    name = "Rene'"<br />
    lastname = "Lamber"<br />
}<br />
Merge-AzTableEntry -table "sampletable" -partitionKey $rene.PartitionKey -rowKey $rene.RowKey -entity $rene<br /><br />

**return a single entry**<br />
$patrickFromTheCloud = Get-AzTableEntry -table "sampletable" -partitionKey $patrick.PartitionKey -rowKey $patrick.RowKey<br /><br />

**update an individual field of an existing entry**<br />
$patrickFromTheCloud = Get-AzTableEntry -table "sampletable" -partitionKey $patrick.PartitionKey -rowKey $patrick.RowKey<br />
$patrickFromTheCloud.name = "Patrick has been updated"<br />
Merge-AzTableEntry -table "sampletable" -partitionKey $patrickFromTheCloud.PartitionKey -rowKey $patrickFromTheCloud.RowKey -entity $patrickFromTheCloud<br /><br />

**get all entries**<br />
$entries = Get-AzTableEntries -table "sampletable"<br /><br />

**select individual fields from the table**<br />
$entriesWithSomeProperties = Get-AzTableEntries -table "sampletable" -select "RowKey,PartitionKey,name"<br /><br />

**filter entries**<br />
$filteredEntries = Get-AzTableEntries -table "sampletable" -filter "name eq 'Patrick'"<br /><br />

**delete an entry**<br />
Remove-AzTableEntry -table "sampletable" -partitionKey $rene.PartitionKey -rowKey $rene.RowKey<br /><br />

**delete a table**<br />
Remove-AzTable -table "sampletable"<br /><br />


