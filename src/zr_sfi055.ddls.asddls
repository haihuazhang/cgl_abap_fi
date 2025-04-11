@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Reconciliation Statements'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
@Metadata.allowExtensions: true
define root view entity ZR_SFI055
  with parameters                                           
   p_FiscalYear: calendaryear,
   p_FiscalPeriod :calendarmonth
  as select from    I_JournalEntryItem   as _JournalEntryItem   
  left outer join  I_Customer  as     _Customer  on _Customer.Customer = _JournalEntryItem.Customer
   left outer join  I_Supplier  as     _Supplier  on _Supplier.Supplier = _JournalEntryItem.Supplier
   left outer join  I_GLAccountText  as    _GLAccountText  on _GLAccountText.GLAccount = _JournalEntryItem.GLAccount
                                                           and _GLAccountText.ChartOfAccounts = 'YCOA'
                                                           and _GLAccountText.Language = 'E'
   left outer join   ztfi_ic_acct     as _Config       on  ( 
            ( _Config.zoption = 'BT' and _JournalEntryItem.GLAccount between _Config.accountfrom and _Config.accountto ) or
            ( _Config.zoption = 'EQ' and _JournalEntryItem.GLAccount = _Config.accountfrom )
        ) 
          left outer join ZR_SFI063  as   _SFI063  on _SFI063.CalendarYear = $parameters.p_FiscalYear
                                           and _SFI063.CalendarMonth = $parameters.p_FiscalPeriod    
{
key  _JournalEntryItem.CompanyCode           as CompanyCode,
  key $parameters.p_FiscalYear                  as FiscalYear,
  key $parameters.p_FiscalPeriod                as  FiscalPeriod,
key  _JournalEntryItem.AccountingDocumentType as AccountingDocumentType,
key  _JournalEntryItem.AccountingDocument     as AccountingDocument,
key  _JournalEntryItem.LedgerGLLineItem       as LedgerGLLineItem,
key  _Config.item                             as    Item,
key  _Config.type                             as   Type,
key  _JournalEntryItem.PartnerCompany          as PartnerCompany,
_JournalEntryItem.PostingDate            as PostingDate,
_JournalEntryItem.DocumentDate           as DocumentDate,
_JournalEntryItem.CreationDate           as CreationDate,
_JournalEntryItem.Customer               as Customer ,
_Customer.CustomerName                   as CustomerName,
_JournalEntryItem.Supplier               as Supplier,
_Supplier.SupplierName                   as SupplierName,
_JournalEntryItem.GLAccount              as GLAccount,
_GLAccountText.GLAccountName             as GLAccountName,
_JournalEntryItem.PostingKey             as PostingKey,
_JournalEntryItem.DebitCreditCode        as DebitCreditCode,
  @Aggregation.default: #SUM 
  @Semantics: { amount : {currencyCode: 'TransactionCurrency'} } 
   cast (  
(coalesce(cast(_JournalEntryItem.AmountInTransactionCurrency as abap.decfloat34),0) ) as zzefi015 ) as AmountInTransactionCurrency,
 @Aggregation.default: #SUM
  @Semantics: { amount : {currencyCode: 'GlobalCurrency'} } 
   cast (  
(coalesce(cast(_JournalEntryItem.AmountInGlobalCurrency as abap.decfloat34),0) ) as zzefi015 ) as AmountInGlobalCurrency,  
 @Aggregation.default: #SUM
  @Semantics: { amount : {currencyCode: 'TransactionCurrency'} } 
     cast (  
(coalesce(cast(_JournalEntryItem.AmountInCompanyCodeCurrency as abap.decfloat34),0) ) as zzefi015 ) as AmountInCompanyCodeCurrency, 
_JournalEntryItem.TransactionCurrency as TransactionCurrency,
_JournalEntryItem.GlobalCurrency as GlobalCurrency,
_JournalEntryItem.ClearingJournalEntry as ClearingJournalEntry,
_JournalEntryItem.ClearingDate as ClearingDate,
_JournalEntryItem.DocumentItemText as DocumentItemText,
_JournalEntryItem.AssignmentReference as AssignmentReference,
_JournalEntryItem.TaxCode as TaxCode ,
 concat('ui#AccountingDocument-manageV2?CompanyCode=',
 concat(_JournalEntryItem.CompanyCode,
 concat('&AccountingDocument=',
 concat(_JournalEntryItem.AccountingDocument,
 concat('&FiscalYear=', $parameters.p_FiscalYear))))) as Url
} where _JournalEntryItem.SourceLedger = '0L'   and _JournalEntryItem.PostingDate <= _SFI063.calendardate
and _JournalEntryItem.PartnerCompany is not initial
