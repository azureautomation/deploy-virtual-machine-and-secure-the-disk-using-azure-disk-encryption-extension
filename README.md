Deploy Virtual Machine And Secure The Disk Using Azure Disk Encryption Extension
================================================================================

            
Overview

This PowerShell script covers a complete case with one virtual machine (Windows Server 2016), with one data disk, Virtual Network, Subnet, Public IP Address, Network Security Group, BGInfo, and Disk Encryption Extensions.

Details

The executing steps are :


Step 1. Create a Resource Group


Step 2. Create Azure Active Directory service principal


Step 3. Create AAD Application


Step 4. Create Azure Key Vault


Step 5. Create Cryptographic Key


Step 6. Give Permissions to the AAD Application access the principal keys


Step 7. Create Virtual Machine


Step 8. Enable BGInfo extension


Step 9. Enable Disk Encryption extension and encrypt the OS disk


 





![Image](https://github.com/azureautomation/deploy-virtual-machine-and-secure-the-disk-using-azure-disk-encryption-extension/raw/master/1731.Note.gif)
**Note** 


Every step in the script can be used as a separated PowerShell code block.The deployment of the script takes 15 - 20 minutes.




 

Instructions on how to execute the .ps1 file

Step 1. Download the File and save it to the drive
**C:\**


Step 2. Open a Powershell with Administrative rights 


Step 3. Suppose that the .ps1 file is downloaded on the C:\ drive and execute the following command 


 




![Image](https://github.com/azureautomation/deploy-virtual-machine-and-secure-the-disk-using-azure-disk-encryption-extension/raw/master/1731.Note.gif)
**Note** 


This script will update on a regular basis.




        
    
TechNet gallery is retiring! This script was migrated from TechNet script center to GitHub by Microsoft Azure Automation product group. All the Script Center fields like Rating, RatingCount and DownloadCount have been carried over to Github as-is for the migrated scripts only. Note : The Script Center fields will not be applicable for the new repositories created in Github & hence those fields will not show up for new Github repositories.
