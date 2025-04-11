@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'invoice item'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
@Metadata.allowExtensions: true
define view entity ZR_SFI044 as select from I_OperationalAcctgDocItem as _AcctgDocItem
left outer join I_CompanyCode as _Company      on _Company.CompanyCode = _AcctgDocItem.CompanyCode
left outer join ztfi011 as  _ztfi011   on  _ztfi011.taxcode = _AcctgDocItem.TaxCode and _ztfi011.taxcounrty = _Company.Country
{
    key _AcctgDocItem.CompanyCode as CompanyCode,
    key _AcctgDocItem.AccountingDocument as AccountingDocument,
    key _AcctgDocItem.FiscalYear as FiscalYear,
    key _AcctgDocItem.AccountingDocumentItem as AccountingDocumentItem,
    _AcctgDocItem.GLAccount as GLAccount, 
    _AcctgDocItem.DocumentItemText  as Describtion,
    _AcctgDocItem.TransactionCurrency,
    @Semantics: { amount : {currencyCode: 'TransactionCurrency'} }
    _AcctgDocItem.AmountInTransactionCurrency as UnitPrice,
    @Aggregation.default: #SUM
    @Semantics: { amount : {currencyCode: 'TransactionCurrency'} }
    
   ( case _AcctgDocItem.DebitCreditCode 
    when 'S' then _AcctgDocItem.AmountInTransactionCurrency * (-1)
    else  _AcctgDocItem.AmountInTransactionCurrency 
     end )
     as NetAmount,
     
    '1'  as  Quality,
    concat(cast( cast( round( _ztfi011.taxrate * 100, 0 ) as abap.int4 ) as abap.char( 20 ) ), '%')  as TaxRate,
    @Aggregation.default: #SUM
    @Semantics: { amount : {currencyCode: 'TransactionCurrency'} }
    cast(
    
    ( cast(   ( case _AcctgDocItem.DebitCreditCode 
    when 'S' then _AcctgDocItem.AmountInTransactionCurrency * (-1)
    else  _AcctgDocItem.AmountInTransactionCurrency 
     end ) as abap.decfloat34)
    
     * cast(_ztfi011.taxrate as abap.decfloat34)  ) as zzefi015 
     
     ) as TaxAmount,
    @Aggregation.default: #SUM
    @Semantics: { amount : {currencyCode: 'TransactionCurrency'} }
    cast(
   ( cast(   ( case _AcctgDocItem.DebitCreditCode 
    when 'S' then _AcctgDocItem.AmountInTransactionCurrency * (-1)
    else  _AcctgDocItem.AmountInTransactionCurrency 
     end ) as abap.decfloat34) * cast(_ztfi011.taxrate as abap.decfloat34)  + cast(_AcctgDocItem.AmountInTransactionCurrency as abap.decfloat34) )
   as zzefi015 ) as GrossAmount
} where  _AcctgDocItem.GLAccount like '600101%' and _AcctgDocItem.Customer not like 'E%'
