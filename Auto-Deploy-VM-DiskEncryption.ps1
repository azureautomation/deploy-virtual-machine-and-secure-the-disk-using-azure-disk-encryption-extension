<#  
 .SYNOPSIS  
    Deploy Virtual Machine And Secure The Disk Using Azure Disk Encryption Extension.  
 .DESCRIPTION  
This PowerShell script covers a complete case with one virtual machine (Windows Server 2016), 
with one data disk, Virtual Network, Subnet, Public IP Address, Network Security Group, BGInfo, and Disk Encryption Extensions.
 
The executing steps are :

Step 1. Create a Resource Group
Step 2. Create Azure Active Directory service principal
Step 3. Create AAD Application
Step 4. Create Azure Key Vault
Step 5. Create Cryptographic Key
Step 6. Give Permissions to the AAD Application access the principal keys
Step 7. Create Virtual Machine
Step 8. Enable BGInfo extension
Step 9. Enable Disk Encryption extension and encrypt the OS disk

|---------------------|
| MANDATORY PARAMETERS|
|---------------------|

.PARAMETER $SubscriptionName 
The Subscription Name
 
.PARAMETER  $RGName 
The Resource Group Name
 
.PARAMETER $Location 
The Location of the Resources 
 
.PARAMETER $ApplicationName 
The Azure Active Directory Application Name

.PARAMETER $KVName 
The Azure Key Vault Name

.PARAMETER $VMName 
The Virtual Machine Name

|----------------|
|OTHER PARAMETERS|
|----------------|

.PARAMETER $CryptoKeyName 
The RSA cryptographic key for the Key Vault

.PARAMETER $ApplicationHomePage
The Name of the Azure Active Directory Application

.PARAMETER $ApplicationURi 
The URI Of the Azure Active Directory Application

.PARAMETER $KeyDestination
The Key Value Protection Type, the default value is 'Software'

.PARAMETER $VNet
The Virtual Network Name

.PARAMETER $VNetSubnet
The Virtual Machine Virtual Network Subnet

.PARAMETER $NetSecGroup
The Virtual Machine Network Security Group

.PARAMETER $VMPublicIP
The Virtual Machine Public IP (Static)

 .NOTES  
    Author: Giorgos Grammatikos 
    Version: 1.0.0 
    DateCreated: 13/09/2018 
 .LINK  
     https://cloudopszone.com 
#>  

Param(

[Parameter(Mandatory = $true,
             HelpMessage="The Subscription Name that the Resource Group and Resources placed in")]
  [ValidateNotNullOrEmpty()]
  [string]$SubscriptionName,

[Parameter(Mandatory = $true, 
             HelpMessage="This is the Resource Group Name")]
  [ValidateNotNullOrEmpty()]
  [string]$RGName,
[Parameter(Mandatory = $true,
             HelpMessage="This is the Location of the Resource Group And the Key Vault, Virtual Machines should be in the same Location")]
  [ValidateNotNullOrEmpty()]
  [string]$Location,


[Parameter(Mandatory = $true,
             HelpMessage="This is the name of the Azure Active Directory Application")]
  [ValidateNotNullOrEmpty()]
  [string]$ApplicationName,

[Parameter(Mandatory = $true,
             HelpMessage="This is the KeyVault Name, which the encryption keys will be placed")]
  [ValidateNotNullOrEmpty()]
  [string]$KVName,


[Parameter(Mandatory = $true,
             HelpMessage="This is the Virtual Machine Name")]
  [ValidateNotNullOrEmpty()]
  [string]$VMName,


[Parameter(Mandatory = $false,
             HelpMessage="This is the RSA cryptographic key for the Key Vault")]
  [ValidateNotNullOrEmpty()]
  [string]$CryptoKeyName,

[Parameter(Mandatory = $false,
             HelpMessage="This is the name of the Azure Active Directory Application")]
  [ValidateNotNullOrEmpty()]
  [string]$ApplicationHomePage,


[Parameter(Mandatory = $false,
             HelpMessage="This is the URI of the Azure Active Directory Application")]
  [ValidateNotNullOrEmpty()]
  [string]$ApplicationURi,


[Parameter(Mandatory = $false,
             HelpMessage="This is the value of the Key Vault Protection type, Software or HSM, by default is select the value Software")]
  [ValidateNotNullOrEmpty()]
  [string]$KeyDestination,

[Parameter(Mandatory = $false,
             HelpMessage="This is the Virtual Network Name")]
  [ValidateNotNullOrEmpty()]
  [string]$VNet,

[Parameter(Mandatory = $false,
             HelpMessage="This is the Virtual Network Subnet Name")]
  [ValidateNotNullOrEmpty()]
  [string]$VNetSubnet,

[Parameter(Mandatory = $false,
             HelpMessage="This is the Network Security Group Name")]
  [ValidateNotNullOrEmpty()]
  [string]$NetSecGroup,

[Parameter(Mandatory = $false,
             HelpMessage="This is the Virtual Machines Public IP Name")]
  [ValidateNotNullOrEmpty()]
  [string]$VMPublicIP


)

#Login To The Azure Account
Login-AzureRmAccount

#Select A Valid Azure Subscription
Select-AzureRmSubscription -Subscription $SubscriptionName

##### CREATE AZURE KEYVAULT & AZURE ACTIVE DIRECTORY APP (AAD APP)


$aadClientSecret = [Guid]::NewGuid().ToString();


#Step 1. 
Register-AzureRmResourceProvider -ProviderNamespace "Microsoft.KeyVault"


#Step 1 Create The Resource Group

#Create Resource Group    
try
{
    $rgroup = Get-AzureRmResourceGroup -Name $RGName -Location $Location -ErrorAction SilentlyContinue
}
catch [System.ArgumentException]
{
Write-Host 'Resource Group :' $RGName 'not exists'
$rgroup=$null;
}
if(-not $rgroup)
{
Write-Host 'Creating new Resource Group:' $RGName
New-AzureRmResourceGroup -Name $RGName -Location $Location

}

#Step 2 Create Azure Active Directory service principal

$secureAadClientSecret = ConvertTo-SecureString -String $aadClientSecret -AsPlainText -Force;


#Step 2.1 Create AAD Application

$ApplicationHomePage = 'http://'+$ApplicationName+'.com'
$ApplicationURi = 'http://'+$ApplicationName

$AADApp = New-AzureRmADApplication -DisplayName $ApplicationName -HomePage $ApplicationHomePage -IdentifierUris $ApplicationURi -Password $secureAadClientSecret
$AADAppID = New-AzureRmADServicePrincipal -ApplicationId $AADApp.ApplicationId

 
#Step 3 Create Azure Key Vault

try
{

$kvault= Get-AzureRmKeyVault -VaultName $KVName `
                             -Location $Location `
                             -InRemovedState `
                             -ErrorAction SilentlyContinue
                             
}
catch [System.ArgumentException]
{
Write-Host 'Key Vault:' $kvault 'not exists'
$kvault=$null;

}
if(-not $kvault)
{
Write-Host 'Creating new key vault:' $KVName
$kvault=New-AzureRmKeyVault -Location $Location `
    -ResourceGroupName $RGName `
    -VaultName $KVName `
    -EnabledForDiskEncryption
}


#Step 4. Create Cryptographic Key

$KeyDestination = 'Software'
$CryptoKeyName = 'key'+$KVName.ToLower()+'name'

$keyvaultkey = Add-AzureKeyVaultKey -VaultName $KVName `
    -Name $CryptoKeyName `
    -Destination $KeyDestination



#Step 5. Give Permissions to the AAD Application access the principal keys

Set-AzureRmKeyVaultAccessPolicy -VaultName $KVName `
    -ServicePrincipalName $AADApp.ApplicationId `
    -PermissionsToKeys "WrapKey" `
    -PermissionsToSecrets "Set"


#####----------------------------------------------#####

#Create Virtual Machine

#Step 1


$VNet = 'VNet'+$RGName.ToLower()
$VNetSubnet = 'VNet'+$VNet.ToLower()+'Subnet'
$VMPublicIP = 'Public'+$VMName.ToLower()+'IP'
$NetSecGroup = 'NSG'+$VNet.ToLower()+'_'
$VMcredentials= Get-Credential

New-AzureRmVm `
    -ResourceGroupName $RGName `
    -Name $VMName `
    -Location $Location `
    -VirtualNetworkName $VNet `
    -SubnetName $VNetSubnet `
    -SecurityGroupName $NetSecGroup `
    -PublicIpAddressName $VMPublicIP `
    -Credential $VMcredentials `
    -Size 'Standard_A2' `
    -Image Win2016Datacenter `
    -DataDiskSizeInGb '127'


# Step 2

Set-AzureRmVMExtension -ResourceGroupName $RGName `
                       -VMName $VMName `
                       -Name "BGInfo" `
                       -Location $Location `
                       -Publisher "Microsoft.Compute" `
                       -typeHandlerVersion "2.1" `
                       -ExtensionType "BGInfo"


#####----------------------------------------------#####

#Encrypt Drive(s) With BitLocker 

#VM Disk Encryption Variables

$KeyVault = Get-AzureRmKeyVault -VaultName $KVName -ResourceGroupName $RGName;
$diskEncryptionKeyVaultUrl = $KeyVault.VaultUri;
$keyVaultResourceId = $keyVault.ResourceId;
$DiskkeyEncrUrl = (Get-AzureKeyVaultKey -VaultName $KVName -Name $keyvaultkey.Name).key.Kid


Set-AzureRmVMDiskEncryptionExtension -ResourceGroupName $RGName `
                                     -VMName $VMName `
                                     -DiskEncryptionKeyVaultUrl $diskEncryptionKeyVaultUrl `
                                     -DiskEncryptionKeyVaultId $KeyVaultResourceId `
                                     -VolumeType OS;



