@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'AcctgDocItem'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZR_SFI036_1 as select from I_OperationalAcctgDocItem as _AcctgDocItem
inner join  ZR_SFI036_2  as _ZTFI006 on _AcctgDocItem.GLAccount  between _ZTFI006.glaccount1 and _ZTFI006.glaccount2
{
    key _AcctgDocItem.CompanyCode,
    key _AcctgDocItem.AccountingDocument,
    key _AcctgDocItem.FiscalYear,
    min(_AcctgDocItem.AccountingDocumentItem) as Item,
    max(_ZTFI006.incomedescribtion) as IncomeDescribtion
}
group by
    _AcctgDocItem.CompanyCode,
    _AcctgDocItem.AccountingDocument,
    _AcctgDocItem.FiscalYear

