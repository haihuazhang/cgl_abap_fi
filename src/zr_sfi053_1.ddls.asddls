@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'B->A AR'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define  view entity ZR_SFI053_1
  with parameters                                           
   p_FiscalYear: calendaryear,
   p_FiscalPeriod :calendarmonth
 as select from ZR_SFI053(p_FiscalPeriod : $parameters.p_FiscalPeriod,p_FiscalYear:$parameters.p_FiscalYear) as _SFI053

left outer join I_CompanyCode as _Company         on _Company.Company = _SFI053.PartnerCompany 
left outer join I_CompanyCode as _CompanyCode     on _CompanyCode.CompanyCode = _SFI053.CompanyCode 
{
    key _Company.CompanyCode     as CompanyCode ,
    key $parameters.p_FiscalYear       as FiscalYear,
    key $parameters.p_FiscalPeriod     as FiscalPeriod,
    key _CompanyCode.Company     as PartnerCompany,
    key _SFI053.Item             as Item,
    key _SFI053.GlobalCurrency          as GlobalCurrency,
    key _SFI053.TransactionCurrency,
//    key _SFI053.PostingDate             as PostingDate,
    @Semantics: { amount : {currencyCode: 'TransactionCurrency'} } 
    _SFI053.TotalAmount,
    @Semantics: { amount : {currencyCode: 'GlobalCurrency'} }
    _SFI053.TotalAmountGlobal
}
