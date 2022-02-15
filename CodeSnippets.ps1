function ExtractGUIandX500OneUser {

    [CmdletBinding(DefaultParameterSetName = "Default")]
    param (
        # User mailbox email address or full display name
        [Parameter(Mandatory = $false)]
        [String]
        $UserMailbox
    )

    #requesting user to input mailbox email address or displayname if not specified
    # this provides flexibility to specify the paramter when calling the function independently
    if (-not($UserMailbox)) {

        Write-Host "`nEnter email address or display name of the mailbox`n"
        Write-host "Example : dlex@hoperoom.com or Daniel Alex`n" -ForegroundColor Yellow
        $UserMailbox = Read-Host "Enter the Mailbox email address "
        $UserMailbox = $UserMailbox.Trim() #split and remove all white spaces from the imput

        Write-Host "Retrieving the DisplayName, PrimarySmtpAddress, ExchangeGUID and LegacyExchangeDN of the mailbox " $UserMailbox
        $ExchGuidLgDN = Get-MailBox  -Identity $UserMailbox | Select-Object DisplayName, PrimarySmtpAddress, ExchangeGuid, LegacyExchangeDN
    }
    else {
        Write-Host "Retrieving the DisplayName, PrimarySmtpAddress, ExchangeGUID and LegacyExchangeDN of the mailbox " $UserMailbox
        $ExchGuidLgDN = Get-MailBox  -Identity $UserMailbox | Select-Object DisplayName, PrimarySmtpAddress, ExchangeGuid, LegacyExchangeDN
    }

    return $ExchGuidLgDN
}



#origal before changes
function ExtractExchGUIandX500 {

    [CmdletBinding(DefaultParameterSetName = "Default")]
    param (
        # User mailbox email address or full display name
        [Parameter(Mandatory = $false)]
        [array]
        $BulkOrOneMailbox
    )

    checkIfCsv = $BulkUserMailbox.split(",").Trim
    

    #for retrieving the mailbox information
    function RetrievMailboxInfo {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory)]
            [array]
            $UserMailbox
        )
        
        # get mailbox information  and return array object
        $UserMailbox | ForEach-Object {
            Get-MailBox -Identity $_ | Select-Object DisplayName, PrimarySmtpAddress, ExchangeGuid, LegacyExchangeDN

            $MailBoxInfo = [PSCustomObject]@{
                DisplayName      = $_.DisplayName
                ExchangeGuid     = $_.ExchangeGuid
                EmailAddress     = $_.PrimarySmtpAddress
                LegacyExchangeDN = $_.LegacyExchangeDN
            }
        }
    }


    #requesting user to input mailbox email address or displayname if not specified
    # this provides flexibility to specify the paramter when calling the function independently
    if (-not($BulkOrOneMailbox)) {



        Write-Host "`nEnter email address or display name of the mailboxes seperated by comma`n"
        Write-host "Example : dlex@hoperoom.com, ernesto@hoperoom.com or Daniel Alex, Ernest Alex `n" -ForegroundColor Yellow
        $BulkOrOne = Read-Host "Enter the Mailbox email address"
        $BulkOrOneMailbox = $BulkOrOne.split(",").Trim() #split and remove all white spaces from the imput

        if ($BulkOrOneMailbox.Length -le 0) {
            #get single mailbox information
            $InfoResults = RetrievMailboxInfo -UserMailbox $BulkOrOneMailbox
            return $InfoResults 
        }
        else {
            Write-Host "You have provided invalid email address or display name"
        }
    }
    elseif(($BulkUserMailbox.split(",").Trim.Length -eq 1) -and (checkIfCsv.ToLower -eq "CSV".ToLower())) {
        # this is single column CSV data without any column name, and it can be a mix of email addressess and display name
        Write-Host "Retrieving the DisplayName, PrimarySmtpAddress, ExchangeGUID and LegacyExchangeDN of the mailbox "
        $getCsvData = Get-CSVFile #get file
        $readCsvData = Get-Content -Path $getCsvData
        
        return RetrievMailboxInfo -UserMailbox $readCsvData

    }else{
        Write-Host "`nEnter email address or display name of the mailboxes seperated by comma`n"
        Write-host "Example : dlex@hoperoom.com, ernesto@hoperoom.com or Daniel Alex, Ernest Alex `n" -ForegroundColor Yellow
        $BulkOrOneMailbox = Read-Host "Enter the Mailbox email address "
        $BulkOrOneMailbox = $UserMailbox.split(",").Trim() #split and remove all white spaces from the imput

        if ($BulkOrOneMailbox.Length -le 0) {
            #get single mailbox information
            $InfoResults = RetrievMailboxInfo -UserMailbox $BulkOrOneMailbox
            return $InfoResults 
        }
        else {
            Write-Host "You have provided invalid email address or display name"
        }
    }

}