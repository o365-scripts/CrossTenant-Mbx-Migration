
#Instruction for each sectiion

$ActionSelection = @"
Select the action you want to perform by entering the corresponding number
______________________________________________________________________________________

CHOICE SELECTION 
=========================================

    1 -- Create one  mailuser on Target/destination tanant"
    2 -- Crete in bulk multiple mailusers by CSV file"
    3 -- Stand ExchangeGUID and LegacyExchangDN"

"@

$BulkMUInst = @"
================ Bulk mail user creation =======================

Provide csv file for bulk. The CSV file must contant 3 columns

Example: 
    Proivde CSV file with 3 columns DisplayName, EmailAddress, Password

    DiaplayName,EmailAddress, Password
    Daniel Alex,dalex@check.com,PassWord!@#
    Daniel Mykel,dykel@check.com,PassWord!@# 

"@

$ExtractBulkorOneInst = @"

================ Bulk User Mailbox Infomation Retrival =======================

Select the corresponding option for data source

    1 -- Enter email address or display name of the mailboxes seperated by comma on single line.
         Example : 
            dlex@hoperoom.com, ernesto@hoperoom.com or Daniel Alex, Ernest Alex

    2 -- Select a CSV file that contain list of users, the should have no header
         Example :
            Daniel Mykel,
            dykel@check.com
            gylex@checj.com
            Atta Amam
            .................. nth

==============================================================================

"@

$ObjectCreationOnTarget = @"

================== Creating MailUsers on Tranger Tenant =======================

Please, any of the domain in the Target Tenant to enable create of MailUser for
migration of user and stamption Echange GUID and X500 address

===============================================================================

"@


#  This function invokes file picker dialog box for the users to select csv file
function Get-CSVFile {
    #get csv file
    [void] [System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    if ($initialDirectory) { $OpenFileDialog.initialDirectory = "." }
    $OpenFileDialog.filter = "CSv files (*.csv)|*.csv"
    $OpenFileDialog.Title = "Select CSV file"
    [void] $OpenFileDialog.ShowDialog()
    return $OpenFileDialog.FileName
}


function CrossT2TMigration {
  
    <#
    .Synopsis
        This script will enable user to automate the of the processess in volved in tenant to tenant mailbox migration.

    .Description
        add later

    .Example
        later   
#>

    [CmdletBinding(DefaultParameterSetName = "Default")]
    param (
        # MailUser principal name
        [Parameter(
            Mandatory = $false, ValueFromPipeline, ValueFromPipelineByPropertyName,
            ParameterSetName = "MailUserPrincipalName"
        )]
        [array]$CreateTargetMailUser,

        [Parameter(Mandatory = $false, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        #[ValidateSet("1", "2","3")] # bulk mailuser creation or single
        [string]$ChoseSelection

    )


    # Choice seelect tion
    Write-Host $ActionSelection

    $ChoseSelection = Read-Host "CHOICE SELECTION  "
    
    switch ($ChoseSelection) {

        "1" {
            CreateOneTragetMailUser 
        }
        "2" { 
            Write-Host 
            

        }
    
        Default { "sdflshlfks" }
    }
}



<################# 

    List of all implemented funtions
    Each major function can be run impendently for independent operation on the source and target tenant.

    

#>

#Creating mail user on source tenant
function New-TragetMailUser {
   
    [CmdletBinding(DefaultParameterSetName = "Default")]
    param (
        # MailUser password
        [Parameter()]
        [string[]] $MailUserPwd
    )

    Write-Host "`nEnter Detail Seperated by comma (,) - DisplayName, MailUserUPN, Passowrd`n"
    Write-host "Example : Daniel Alex, dlex@hoperoom.com, Passw0rd!@# `n" -ForegroundColor Yellow
    $MailUserDetail = Read-Host "Entert the mail user detail "
    $MailUserDetail = $MailUserDetail.Split(",").Trim().Trim("'").Trim('"') #split and remove all white spaces from the imput

    Write-Host $MailUserDetail
    if ($MailUserDetail[1].ToLower().Contains("@") -eq $true) {
        #create  mail user with entered data
        New-MailUser -Name $MailUserDetail[0]  -MicrosoftOnlineServicesID  $MailUserDetail[1] -DisplayName $MailUserDetail[0] `
            -Password (ConvertTo-SecureString -String $MailUserDetail[2] -AsPlainText -Force)
    }
    else {
        $pvd = $MailUserDetail[1] #email check
        Write-Host "Invalid import, email/UPN must contain the @ character. You entered $pvd " -ForegroundColor Red
    }
        
}


#Creating mail user on source tenant

function New-BulkTargetMailUser {

    <#
    .Synopsis
    Create bulk users on the target tenant
    .DESCRIPTION
    This function enable admin to create needed mail users on the target tenant for migration.

    .EXAMPLE
    New-BulkTargetMailUser -BulkUserData <Array of Mailboxes in a table format>

    $myMailBoxes = Import-csv "file path" # can also use get-content
    New-BulkTargetMailUser -BulkUserData

    .FUNCTIONALITY
    Create MailUser in bulk for the retrived content supplied by the csv file. The colomnn must contain
    DiaplayName, EmailAddress, password. Object creation will fail if the mention colums are not available. 

    #>

    
    [CmdletBinding(DefaultParameterSetName = "Default")]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateScript({
                if (Test-Path $_) { $true }
                else { throw "Path $_ is not valid" }
            })]
        [string]$BulkUserData
    )

    # get CSV file
    if (-not($BulkUserData)) { $BulkUserData = Get-CSVFile }

    # Read CSV file
    $LoadBulkUserData = Import-Csv -Path $BulkUserData
    
    #creating users
    Write-Host "`nMailuser object creation started`n--------------------------------------" -ForegroundColor Green
    $LoadBulkUserData | ForEach-Object { `
            New-MailUser -Name $_.DiaplayName -MicrosoftOnlineServicesID $_.EmailAddress  -DisplayName $_.DiaplayName `
            -Password (ConvertTo-SecureString -String $_.Password -AsPlainText -Force)
        Write-Host "`tDone: " $_.DiaplayName
    }
    Write-Host "--------------------------------------`nMailuser object creation completed" -ForegroundColor Green
        
}


<#
    This function is designed to retrive user propertions for a given mailbox
    The mailbox or mailboxes can be supplied inline data seperated by comma or 
    by csv file with single but not header. The column can be mix user "Display Name" or email address

    Restults:
        This will return a table formated file and can be exported as csv file.
#>

#for retrieving the mailbox information
function Get-MailboxRequiedInfo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [array]
        $UserMailbox
    )
    
    # get mailbox information  and return array object
    $MailBoxInfo = @()
    $UserMailbox | ForEach-Object {
        Get-MailBox -Identity $_ | Select-Object DisplayName, PrimarySmtpAddress, ExchangeGuid, LegacyExchangeDN

        $Info = [PSCustomObject]@{
            DisplayName      = $_.DisplayName
            ExchangeGuid     = $_.ExchangeGuid
            EmailAddress     = $_.PrimarySmtpAddress
            LegacyExchangeDN = $_.LegacyExchangeDN
        }

        $MailBoxInfo += $Info
    }

    return $MailBoxInfo
}

function Get-ExchGUIandX500FromSource {

    [CmdletBinding(DefaultParameterSetName = "Default")]
    param (
        # User mailbox email address or full display name
        [Parameter(Mandatory = $false)]
        [array]
        $BulkOrOneMailbox,

        #export results as csv
        [Parameter(Mandatory = $false)]
        [bool]
        $ExportResultAs = $false
    )

    #requesting user to input mailbox email address or displayname if not specified
    # this provides flexibility to specify the paramter when calling the function independently
    if (-not($BulkOrOneMailbox)) {

        Write-Host $ExtractBulkorOneInst

        $DataSource = Read-Host " CHOICE SELECTION (1 or 2) "

        Write-Host "`n"
        
        switch ($DataSource) {
            "1" { 
                $BulkOrOne = Read-Host "Enter the Mailbox email address"
                $BulkOrOneMailbox = $BulkOrOne.split(",").Trim().Trim("'").Trim('"') #split and remove all white spaces from the imput

                if ($BulkOrOneMailbox.Length -ge 1) {
                    #get single mailbox information
                    $MailboxInfoResults = Get-MailboxRequiedInfo -UserMailbox $BulkOrOneMailbox
                    return $MailboxInfoResults 
                }
                else {
                    Write-Host "You have provided invalid email address or display name"
                }
            }
            "2" {
                # this is single column CSV data without any column name, and it can be a mix of email addressess and display name
                Write-Host "Retrieving the DisplayName, PrimarySmtpAddress, ExchangeGUID and LegacyExchangeDN of the mailbox "
                $getCsvData = Get-CSVFile #get file
                $readCsvData = Get-Content -Path $getCsvData
                    
                $MailboxInfoResults = Get-MailboxRequiedInfo -UserMailbox $readCsvData
                return $MailboxInfoResults
            
            }
            Default { Write-Host "Invalid selected choice" }
        }
        
    }
    else {
    
        $BulkOrOne = $BulkOrOneMailbox.split(",").Trim() #split and remove all white spaces from the imput

        if ($BulkOrOne.Length -ge 1) {
            #get single mailbox information
            $MailboxInfoResults = Get-MailboxRequiedInfo -UserMailbox $BulkOrOne
            return $MailboxInfoResults 
        }
        else {
            Write-Host "You have provided invalid email address or display name"
        }
    }

}


function ValidateProperties {
    #Valid the presence of "DisplayName","LegacyExchangeDN","ExchangeGuid"
    param (
        [Parameter(Mandatory)]
        [array]
        $MailboxDataSet
    )

    $columns = ($MailboxDataSet | Get-Member).Name
    $requireColumn = "DisplayName", "LegacyExchangeDN", "ExchangeGuid"

    return (($requireColumn[0] -in $columns) -and ($requireColumn[1] -in $columns) -and ($requireColumn[2] -in $columns)) 
}

function Update-ExchGuidx500ToTarget {

    <#
    .Synopsis
    Transfer mailbox information from source tanant to target tenant. Must be connected to TARGET TENANT exchange online
    .DESCRIPTION
    This
    .EXAMPLE
    Tranfer-ExchGuidx500ToTarget -UserMailbox <Array of Mailboxes>
    .FUNCTIONALITY
    Select each mailbox in the arrays of mailboxes and stamps or transfer LegacyExchangeDN and ExchangeGuid from
    the source mailbox to target tenant's corresponding mailuser mapping by ExchangeGuid 
    #>

    [CmdletBinding()]
    param (
        # This is an array of mailbox information retrieved from the source Tangent.
        # The array column must include the following
        # if this parameter is NOT defined, you will be prompt to select the csv file that contains mailbox info from SOURCE TENANT
        # which contain all the required columns
        [Parameter(Mandatory = $false)]
        [array]
        $ExtractedUMailBoxInfo

    )
    process {

        If (-not($ExtractedUMailBoxInfo)) {
            # get and import mailbox info
            $ExtractedUMailBoxInfo = Import-csv -Path (Get-CSVFile)
        }
       
        # data column validation and transfer
        if ((ValidateProperties -MailboxDataSet $ExtractedUMailBoxInfo) -eq $true) {

            Write-Host "`tLegacyExchangDN  and ExchangeGUID proprty transfer started...........`n" -ForegroundColor Green
            #loop through all the mailbox
            $ExtractedUMailBoxInfo | ForEach-Object {
                Set-MailUser -identity $_.DisplayName -ExchangeGuid $_.ExchangeGUID -EmailAddresses @{add="X500:" + $_.LegacyExchangDN } 
            }
            Write-Host "`t`n....LegacyExchangDN  and ExchangeGUID proprty transfer started.`n" -ForegroundColor Green

        }
        else {
            Write-Host "Invalid the data conlumn format" -ForegroundColor Red
        }
    }
    
}

function TranferSourceToTarget {

    [CmdletBinding(DefaultParameterSetName = "Default")]
    param (
        # SourceTenant, This paramter is mandatory and used in command prefix for destinguish destination and source
        [Parameter(Mandatory)]
        [string]
        $SourceTenantName,

        # Target or Destination Tenant. This paramter is mandatory and used in command prefix for destinguish destination and source
        [Parameter(Mandatory)]
        [String]
        $TargetTenantName,

        # sepecify the migration security group from source tenant, this is also called the migration scope
        [Parameter(Mandatory)]
        [String]
        $SourceTenantMigratSecurityGroup,

        # this is not mandatory, sepecify the migration security group from traget tenant tenant, this is also called the migration scope
        [Parameter(Mandatory = $false, ParameterSetName = "TargetTenantMigratSecurityGroup")]
        [String]
        $TargetTenantMigratSecurityGroup,

        #this is not mandatory and can be specified for the all mailusers for migration not yet create on target tenant
        [Parameter(Mandatory, ParameterSetName = "UsersDoNotExistOnTarget")]
        [switch]
        $UsersDoNotExistOnTarget,

        #specify domain for create new mail user on target tenant
        [Parameter(Mandatory, ParameterSetName = "UsersDoNotExistOnTarget",
            HelpMessage = "Domain on which mail user should be created")]
        [Parameter(Mandatory = $false)]
        [string]
        $TargetDomainForNewMailUsers
    )

    
    <#
        Its recommneded to use the same Display Name from the source tenant aids the transfer of object properties

        Automated process
        ===========================
            Get source properties using 
                $userpros = ExtractExchGUIandX500 functiFromSourceon
            Connect to target tenant
                Connect-exchangeOnline #target tenant admin
            Use the properties from $userpros to stamp it on the target mail users
                $userpros | ForEach-Object { Set-MailUser -identity $_.DisplayName -ExchangeGUID [GUID]$_.ExchangeGuid -EmailAddresses@{add="x500"$_.LegacyExchangDN}}
            Use the display name from the retrieved data

        Manual process
        ==========================
        Another way is to manually map the object from the destination to source properties
        
        To get source properties use
            Extract-ExchGUIandX500FromSource, 
            export the results as csv
            Open the csv file
            Create new column and the mail user emails address from the target tenant.
    #>

    # Concatenation of commandes: 
    # $cmd = "get-"+$gd+"Mailbox  "+$UPN
    # Implementing the Invoke-Expression command to convert the string to a command.
    # Invoke-Expression $cmd

    #Connect to exchange Online for the source tenant
    Connect-ExchangeOnline -Prefix $SourceTenantName

    #Connect to exchange Online for the target tenant
    Connect-ExchangeOnline -Prefix $TargetTenantName

    #Getting all user from migration mail-enabled security group
    $GroupMember = Invoke-Expression ("get-" + $SourceTenantName + "DistributionGroupMember  " + $SourceTenantMigratSecurityGroup)

    #for retrieving the mailbox information for all mailboxes in the the Migration security group
    $MailboxInfoAll = @()
    $GroupMember | ForEach-Object {
            
        $EachUser = Invoke-Expression("get-" + $SourceTenantName + "MailBox -Identity " + $_ ) | Select-Object DisplayName, PrimarySmtpAddress, ExchangeGuid, LegacyExchangeDN

        $MailBoxInfo = [PSCustomObject]@{
            DisplayName      = $EachUser.DisplayName
            ExchangeGuid     = $EachUser.ExchangeGuid
            EmailAddress     = $EachUser.PrimarySmtpAddress
            LegacyExchangeDN = $EachUser.LegacyExchangeDN
        }

        $MailboxInfoAll += $MailBoxInfo
    }

    #get all the equivalent mail users from destination or target tenant.
    
    # Propertity check.
    # If the $UsersDoNotExistOnTarget is set to false, the objects will be created automatically on the target tenant.
    If ($UsersDoNotExistOnTarget) {
        
        # showing instruction
        Write-Host $ObjectCreationOnTarget
        $TargetDomainForNewMailUsers 

        # validating domain if included in accepted domains. if not in included, select the default domain
        if ($TargetDomainForNewMailUsers -notin (Invoke-Expression("get-" + $TargetTenantName + "AcceptedDomain")).DomainName ) {
            $allDomains = (Invoke-Expression("get-" + $TargetTenantName + "AcceptedDomain")) | Select-Object DomainName, Default
            Write-Host "`nThe domain provided in not included in your accepted domains. `nYour accepted domains are : `n`nDOMAINS`n===================="
            $allDomains | Out-String | ForEach-Object { Write-Host $_ }

            #selected domain
            $TargetDomainForNewMailUsers = ($allDomains | where-object { $_.Default -eq "True" }).DomainName
            Write-host "`n`nSetting mail user creation domain to the tenant default domain : " + $TargetDomainForNewMailUsers
        }
        
        Write-Host "`n ========================== Creating Mail Users on Target Tanant ========================`n"
        $MailUserPwd = Read-Host "ENTER DEFAULT PASSWORD FOR NEW MAIL USER CREATION ON TARGET " 
        
        Write-host "`n`n"

        $MailboxInfoAll | ForEach-Object {
            $MailUserAddress = ($MailUserDetail.PrimarySmtpAddress.split("@")[0] + "@" + $TargetDomainForNewMailUsers).ToLower() #split and remove all white spaces from the imput

            #create  mail user with entered data
            Invoke-Expression("New-" + $TargetTenantName + "MailUser -Name " + $_.DisplayName + " -MicrosoftOnlineServicesID " + $MailUserAddress + " -DisplayName " + $_.DisplayName + " -Password (ConvertTo-SecureString -String " + $MailUserPwd + " -AsPlainText -Force)")
        }
    
    }

    # Get all the scope mail user from the target and stamp them with Exchange GUID and Lagacy DN from source.
    Write-Host "`tLegacyExchangDN  and ExchangeGUID proprty transfer started...........`n" -ForegroundColor Green
    #loop through all the mailbox
    $MailboxInfoAll | ForEach-Object {
        Invoke-Expression( "Set-" + $TargetTenantName + "MailUser -identity " + $_.DisplayName + " -ExchangeGuid " + $_.ExchangeGUID + " -EmailAddresses @{add=" + "`"X500:" + $_.LegacyExchangeDN + "`"}")
    }
    Write-Host "`t`n....LegacyExchangDN  and ExchangeGUID proprty transfer started.`n" -ForegroundColor Green

}

# This code is ready for tenant to tenant object preparation for migration 