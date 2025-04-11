@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Invoice header'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define root view entity ZR_SFI038
  as select from    I_JournalEntry as _JournalEntry
   inner join   ZR_SFI036 as _AcctgDocItem on  _AcctgDocItem.CompanyCode        = _JournalEntry.CompanyCode
                                                     and _AcctgDocItem.FiscalYear         = _JournalEntry.FiscalYear
                                                     and _AcctgDocItem.AccountingDocument = _JournalEntry.AccountingDocument                                                    
   left outer join   ZR_SFI036_1 as _AcctgDocItem1 on  _AcctgDocItem1.CompanyCode        = _JournalEntry.CompanyCode
                                                     and _AcctgDocItem1.FiscalYear         = _JournalEntry.FiscalYear
                                                     and _AcctgDocItem1.AccountingDocument = _JournalEntry.AccountingDocument 
   left outer  join  I_HouseBankAccountLinkage as _HouseBankAccountLinkage on  _HouseBankAccountLinkage.HouseBankAccount    = _AcctgDocItem.HouseBankAccount
                                                                           and _HouseBankAccountLinkage.CompanyCode    = _AcctgDocItem.CompanyCode
                                                                           and _HouseBankAccountLinkage.HouseBank    = _AcctgDocItem.HouseBank                                                   
                                                                                                                                                
    left outer join I_CompanyCode as _Company      on _Company.CompanyCode = _JournalEntry.CompanyCode
    left outer join I_OrganizationAddress as _OrganizationAddress on _Company.AddressID = _OrganizationAddress.AddressID
    left outer join ztfi008       as _AdditionInfo on  _AdditionInfo.companycode        = _JournalEntry.CompanyCode
                                                   and _AdditionInfo.fiscalyear         = _JournalEntry.FiscalYear
                                                   and _AdditionInfo.accountingdocument = _JournalEntry.AccountingDocument
    left outer join I_Customer    as _Customer   on  _Customer.Customer =  _AcctgDocItem.Customer 
    left outer join I_OrganizationAddress as _OrganizationAddressCus on _Customer.AddressID = _OrganizationAddressCus.AddressID
    
    left outer join I_CountryVH   as _CountryVH  on _CountryVH.Country =  _Customer.Country
    left outer join I_RegionText  as _RegionText  on _RegionText.Region = _Customer.Region  and _RegionText.Country =  _Customer.Country
                                                    and _RegionText.Language = $session.system_language
    association to one I_Businesspartnertaxnumber as _taxnumberSK0 on _taxnumberSK0.BusinessPartner = _Customer.Customer     
                                                  and _taxnumberSK0.BPTaxType = 'SK0' 
    association to one I_Businesspartnertaxnumber as _taxnumberSK1 on _taxnumberSK1.BusinessPartner = _Customer.Customer 
                                                  and _taxnumberSK1.BPTaxType = 'SK1'     
    association to one I_Businesspartnertaxnumber as _taxnumberSK2 on _taxnumberSK2.BusinessPartner = _Customer.Customer     
                                                  and _taxnumberSK2.BPTaxType = 'SK2' 
    association [0..*] to ZR_SFI046T      as _InvoiceStatusText    on  $projection.Status = _InvoiceStatusText.value_low
    association to many ZR_SFI044 as _Item on  $projection.AccountingDocument   = _Item.AccountingDocument
                                                    and $projection.FiscalYear   = _Item.FiscalYear
                                                    and $projection.CompanyCode  = _Item.CompanyCode
    association [0..*] to ZR_SFI054T      as _DocumentStatus    on  $projection.DocumentStatus = _DocumentStatus.value_low                                               

{
//head
  key _JournalEntry.CompanyCode             as CompanyCode,
  key _JournalEntry.FiscalYear              as FiscalYear,
  key _JournalEntry.AccountingDocument      as AccountingDocument,
//      _Company.CompanyCodeName               as CompanyName,
      concat( _OrganizationAddress.AddresseeName1,  _OrganizationAddress.AddresseeName2 ) as CompanyName,
      _JournalEntry.AccountingDocumentType as AccountingDocumentType,
      _JournalEntry.PostingDate             as PostingDate,
      _JournalEntry.DocumentDate             as Documentdate,
      
      
      
        case 
        when _JournalEntry.ReverseDocument is initial  then 'N'
        else 'R'
      end as DocumentStatus,
  
      _AcctgDocItem1.IncomeDescribtion       as IncomeDescribtion,
      _AcctgDocItem.TransactionCurrency      as TransactionCurrency,
      @Semantics: { amount : {currencyCode: 'TransactionCurrency'} }
      _AcctgDocItem.AmountInTransactionCurrency as TotalGrossAmount,
      _AcctgDocItem.Customer                 as Customer,
      _AdditionInfo.invoicenumber            as InvoiceNo ,  
      _AcctgDocItem.PaymentReference        as ConstantSymbol,
      
//Invoice Head      
       _JournalEntry.DocumentDate            as InvoiceDate,
       _JournalEntry.TaxFulfillmentDate      as TaxFulfillmentDate,
       ''                                    as FinalRecipient,                        
       ''                                    as OrderNumber,
       ''                                    as OrderDate,
       _AcctgDocItem.NetDueDate              as DueDate,
       
        'Príkazom'                           as PaymentMethod, 
  
        
//Buyer Information
       _AcctgDocItem.Customer                 as CustomerCode,
       concat( _Customer.BusinessPartnerName1 ,  _Customer.BusinessPartnerName2  ) as CustomerName,
 //      _Customer.BPCustomerFullName           as CustomerName,
       _Customer.CityName                     as CustomerCity,
       _CountryVH.Description                 as CustomerCountry,
       _RegionText.RegionName                 as CustomerRegion,
       _OrganizationAddressCus.PostalCode        as CustomerPostalCode,
       _OrganizationAddressCus.HouseNumber       as CustomerHouseNumber,
       _OrganizationAddressCus.StreetName        as CustomerStreetName,
      _taxnumberSK2.BPTaxNumber                 as BusinessIdentificationNumber,
      _taxnumberSK1.BPTaxNumber                 as TaxIdentificationNumber,
      _taxnumberSK0.BPTaxNumber                 as VatIdentificationNumber,
       
//Seller Information
        _Company.Country                        as CompanyCountry,
        _Company.CityName                       as CompanyCity,
        _OrganizationAddress.PostalCode         as    CompanyPostalCode,
        _OrganizationAddress.HouseNumber        as    CompanyHouseNumber,
        _OrganizationAddress.StreetName         as    CompanyStreetName,
        _OrganizationAddress.AddresseeName3     as    BusinessIdentificationNumber1,
        _OrganizationAddress.AddresseeName4     as    TaxIdentificationNumber1,
        _Company.VATRegistration                as    VATIdentificationNumber1,     

//Bank Information   

          _HouseBankAccountLinkage.BankName  as BankName ,
          _HouseBankAccountLinkage.HouseBank as HouseBank,
          _HouseBankAccountLinkage.SWIFTCode as Swift,
          _HouseBankAccountLinkage.IBAN as Iban,
          _HouseBankAccountLinkage.BankInternalID as BankKey,
          _HouseBankAccountLinkage.HouseBankAccount as AccountId,
          _HouseBankAccountLinkage.BankAccount as BankAccount,
          substring(_HouseBankAccountLinkage.IBAN, 5, 4) as BankKey_SK,
        
      //      PaymentMethod

//      _AdditionInfo.bankname                 as BankName,
//      _AdditionInfo.housebank                as HouseBank,
//      _AdditionInfo.swift                    as Swift,
//      _AdditionInfo.iban                     as Iban,
//      _AdditionInfo.bankkey                  as BankKey,
//      _AdditionInfo.accountid                as AccountId,
//      _AdditionInfo.bankaccount              as BankAccount,
      _AdditionInfo.invoicenumber            as InvoiceNumber,
//      _AdditionInfo.constantsymbol           as ConstantSymbol,
      _AdditionInfo.invoiceinstructions      as InvoiceInstructions,
      _AdditionInfo.issueremail              as IssuerEmail,
      _AdditionInfo.issuername               as IssuerName,
      
      case 
        when _AdditionInfo.status is null or _AdditionInfo.status = '' then '20'
        else _AdditionInfo.status
    end as Status,
      
 //     _AdditionInfo.status                   as Status,
      //      _AdditionInfo.created_by            as CreatedBy,
      //      _AdditionInfo.created_at            as CreatedAt,
      @Semantics.user.lastChangedBy: true
      _AdditionInfo.lastchangedby            as LastChangedBy,
      @Semantics.systemDateTime.lastChangedAt: true
      _AdditionInfo.lastchangedat            as LastChangedAt,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      _AdditionInfo.locallastchangedat       as LocalLastChangedAt,
      _Item,
      _InvoiceStatusText,
      _DocumentStatus 
} where _JournalEntry.AccountingDocumentType = 'DR' //and _JournalEntry.ReverseDocument is initial
