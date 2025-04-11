@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'B->A AR'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define root view entity ZR_SFI052_1 
  with parameters                                           
   p_FiscalYear: calendaryear,
   p_FiscalPeriod :calendarmonth
as select from ZR_SFI052(p_FiscalPeriod : $parameters.p_FiscalPeriod,p_FiscalYear:$parameters.p_FiscalYear) as _SFI052
left outer join I_CompanyCode as _Company         on _Company.Company = _SFI052.PartnerCompany 
left outer join I_CompanyCode as _CompanyCode     on _CompanyCode.CompanyCode = _SFI052.CompanyCode 
{
    key _Company.CompanyCode     as CompanyCode ,
    key $parameters.p_FiscalYear       as FiscalYear,
    key $parameters.p_FiscalPeriod     as FiscalPeriod,
    key _CompanyCode.Company     as PartnerCompany,
    key _SFI052.Item              as Item,
    key _SFI052.TransactionCurrency,
    key _SFI052.GlobalCurrency          as GlobalCurrency,
//    key _SFI052.PostingDate             as PostingDate,
    @Semantics: { amount : {currencyCode: 'TransactionCurrency'} } 
    _SFI052.TotalAmount,
    @Semantics: { amount : {currencyCode: 'GlobalCurrency'} }
    _SFI052.TotalAmountGlobal
}
