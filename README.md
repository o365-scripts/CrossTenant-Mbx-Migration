# CrossTenantMigration

## This is based on the steps in 
https://docs.microsoft.com/en-us/microsoft-365/enterprise/cross-tenant-mailbox-migration?view=o365-worldwide 

In performing cross-tenant migration, we encountered some steps which could be be automated; hence this script.

<br>

# Detailed Migration Steps

This gives step by step process for migration mailbox from tenant to
tenant

## Pre-requisites
-   Global admin access to both tenants

> Target (destination): This where the mailbox will be moved to. o365Training
> 
>Source (origination): this is where the mailbox will be migrated from. GritDev

<br>

## **Preparing Target**

**Migration App Creation and Permission Concert**

1.  Visit portal.azure.com \> Click view under Manage Azure Active
    Directory
2.  Select App registration \> Select New registration
     > Provide Detail \| Support account type:
     >
     > Select \"**Accounts in any organizational directory (Any Azure AD directory - Multitenant)**\"

3. Select Register
   > ![](.//media/image1.png)
4.  Click App Registration \> Under Owned applications, select the new
    app created.
5.  Under \^**Essentials**,
    >  Copy down the Application (client) ID, the will be used to create a URL for the target tenant.
    >
    > ![](.//media/image2.png)

6.  Now, on the left navigation bar, click on API permissions to view permissions assigned to your app.
    
    > By default, **User. Read permissions** are assigned to the app you created,
    > - We do not require them for mailbox migrations,
    > - You can remove that permission by clicking the **3dots** and Select **remove permission**
        
    >>  ![](.//media/image3.png)

7.  Assign require permission to the app
    > -   To add permission for mailbox migration, select Add a permission
    > -   In the Request API permissions windows, select **APIs my organization users**, and select for **office 365 exchange online**.
    > -   Select **Application permission**
    > -   Under **Select permissions**, expand **Mailbox**, and check **Mailbox.Migration**, and **Add permissions**
    >
    > > ![](.//media/image4.png)
     ![](.//media/image5.png)

8.  Certificates and Secretes
    > -   Under Client secrets, select new client secret.
    > -   Configure client secrete and expiration date \> click add
    > -   Make note of the secret and value
    
      > > ![](.//media/image6.png)
       ![](.//media/image7.png)
       ![](.//media/image8.png)

9.  Grant Consent for the **target tenant**
    > - To consent to the application, go back to the Azure Active Directory landing page,
    > - click on Enterprise applications \> Select your custom   application
    > -  Select permission in the navigation \> Click on the Grant admin
    consent for \[your tenant\] button
    
    > > ![](.//media/image9.png)
        ![](.//media/image10.png)   

10. Grant consent for **Source Tenant** using app id from target tenant
    > - Formulate the URL to send to your trusted partner (source tenant
    admin)
    > - https://login.microsoftonline.com/sourcetenant.onmicrosoft.com/adminconsent?client_id=\/**[application_id_of_the_app_you_just_created_from_the_target_tenant\]**&redirect_uri=https://office.com

    > - Paste the formulate URL in the browser

    > ![](.//media/image11.png)

<br>

## $\color{#f09c15}{Important }$ Note 
  > ![](.//media/image12.png)

<br>

## **Create migration Endpoint & organization relationship on target**
----
**Needed**:

-   Application ID (target), password\[secret\] (target), source tenant default domain
-   Also depending on the Microsoft 365 Cloud Instance you use your endpoint may be different
    > https://docs.microsoft.com/en-us/microsoft-365/enterprise/microsoft-365-endpoints?view=o365-worldwide

1.  Connect Exchange Online PowerShell

    > <code> Connect-exchangeOnline #sign in with admin account for target tenant </code>

2.  Create a new migration endpoint

    <code>

    \$AppId = \"\[***guid copied from the migrations app created on target
    tenant***\]\"

    \$Credential = New-Object -TypeName
    System.Management.Automation.PSCredential -ArgumentList \$AppId, (ConvertTo-SecureString -String \"\[***this is your secret password you saved in the previous steps on the target tenant***\]\" -AsPlainText -Force)

    New-MigrationEndpoint -RemoteServer outlook.office.com -RemoteTenant \"**sourcetenant.onmicrosoft.com\"** -Credentials \$Credential -ExchangeRemoteMove:\$true -Name \"\[the name of your migration endpoint\]\" -ApplicationId \$AppId
    </code>

3.  Create new or edit your existing organization relationship object to
    your source tenant

    <code> 
    
    \$sourceTenantId= \"\[tenant id of your trusted partner, where the source mailboxes are, source\]\"

    \$orgrels=Get-OrganizationRelationship

    \$existingOrgRel = \$orgrels \| ?{\$\_.DomainNames -like \$sourceTenantId}

    If (\$null -ne \$existingOrgRel)
    {
     Set-OrganizationRelationship \$existingOrgRel.Name -Enabled:\$true -MailboxMoveEnabled:\$true -MailboxMoveCapability Inbound
    }

    If (\$null -eq \$existingOrgRel)
    {
    New-OrganizationRelationship \"\[name of the new organization relationship\]\" -Enabled:\$true -MailboxMoveEnabled:\$true -MailboxMoveCapability Inbound -DomainNames \$sourceTenantId
    }
    </code>

<BR>

## **Accept and Consent Migration App and configuring the organization relationship on Source (current mailbox location)**

1.  Formulate the URL to send to your trusted partner (source tenant
    admin)
2. Paste the formulate URL in the browser \> Sign in with source tenant
    account \> Accept the terms.
    >  https://login.microsoftonline.com/sourcetenant.onmicrosoft.com/adminconsent?client_id=\[application_id_of_the_app_you_just_created_from_the_target_tenant\]&redirect_uri=https://office.com
    >
    >  Application will be added your Azure Active Directory portal under
    Enterprise applications

3.  Create new or edit organization relationship

    <code> \$targetTenantId=\"\[tenant id of your target tenant, where the mailboxes are being moved to\]\"

    \$appId=\"\[application id of the mailbox migration app you consented to\]\"

    \$scope=\"\[name of the mail enabled security group that contains the list of users who are allowed to migrate (source)\]\"

    \$orgrels=Get-OrganizationRelationship

    \$existingOrgRel = \$orgrels \| ?{\$\_.DomainNames -like \$targetTenantId}

    If (\$null -ne \$existingOrgRel)
    {

    Set-OrganizationRelationship \$existingOrgRel.Name -Enabled:\$true -MailboxMoveEnabled:\$true -MailboxMoveCapability RemoteOutbound -OAuthApplicationId \$appId -MailboxMovePublishedScopes \$scope
    }

    If (\$null -eq \$existingOrgRel)
    {

       New-OrganizationRelationship \"\[name of your organization relationship\]\" -Enabled:\$true -MailboxMoveEnabled:\$true -MailboxMoveCapability RemoteOutbound -DomainNames \$targetTenantId    -OAuthApplicationId \$appId -MailboxMovePublishedScopes \$scope

    }

    </code>

<br>

## $\color{#f09c15}{Important }$ Note
![](.//media/image13.png)

<br>

## **Target And Source Object Preparation**

- Example **target** (Destination) MailUser object: 
<br>

    >  ![](.//media/image17.png)

- Example **source** (origin) Mailbox object:
<br>

   >  ![](.//media/image18.png)

## **Further Information on Prerequisites for target user objects**
<br>

   >  ![](.//media/image14.png)

<br>

## **Test Migration Connectivity and success**

1.  Test Endpoint server reachability

    <code> 
    
    > Test-MigrationServerAvailability -Endpoint \"\[the name of your cross-tenant migration endpoint\]\" 
    >
    > Test-MigrationServerAvailability -Endpoint T2TMailboxMigration
    </code>

2.  Test Migration Success for a source mailbox that must be migrated

    <code> 

    > Test-MigrationServerAvailability -Endpoint \"\[the name of your cross-tenant migration endpoint\]\" -TestMailbox \"\[email address of a source mailbox that is part of your migration scope\]\"
    >
    > Test-MigrationServerAvailability -Endpoint T2TMailboxMigration -TestMailbox LaraN@o365TrainDev.onmicrosoft.com
    </code>

    > ![](.//media/image15.png)

<br>

## **Troubleshooting**

> The following happens if the LagacyExchangeDN to from the source mailbox has not been added as x500 proxy address on the target mail user.

 > ![](.//media/image16.png)



## **References**

 > https://docs.microsoft.com/en-us/microsoft-365/enterprise/cross-tenant-mailbox-migration?view=o365-worldwide#prepare-target-user-objects-for-migration

 