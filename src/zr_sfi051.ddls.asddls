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
define root view entity ZR_SFI051
  with parameters                                     
   p_FiscalYear: calendaryear,
   p_FiscalPeriod :calendarmonth
  as select from    ZR_SFI051_1(p_FiscalPeriod : $parameters.p_FiscalPeriod,p_FiscalYear:$parameters.p_FiscalYear)  as _JournalEntryItem  
  left outer join I_CompanyCode as _CompanyCode         on _CompanyCode.CompanyCode = _JournalEntryItem.CompanyCode 
  left outer join I_CompanyCode as _Company             on _Company.Company =  _JournalEntryItem.PartnerCompany   
  left outer join I_BusinessPartner as _BusinessPartner      on _BusinessPartner.BusinessPartner = _JournalEntryItem.PartnerCompany 
  left outer join ZR_SFI052(p_FiscalPeriod : $parameters.p_FiscalPeriod,p_FiscalYear:$parameters.p_FiscalYear)
                                                          as   _sfi052     on         _sfi052.CompanyCode     = _JournalEntryItem.CompanyCode
                                                          //and  _sfi052.FiscalYear            = _JournalEntryItem.FiscalYear
                                                          //and  _sfi052.FiscalPeriod          = _JournalEntryItem.FiscalPeriod
                                                          and  _sfi052.PartnerCompany        = _JournalEntryItem.PartnerCompany 
                                                          and  _sfi052.TransactionCurrency   = _JournalEntryItem.TransactionCurrency
                                                          and  _sfi052.GlobalCurrency        = _JournalEntryItem.GlobalCurrency 
                                                          and  _sfi052.Item                  = _JournalEntryItem.Item
  left outer join ZR_SFI053(p_FiscalPeriod : $parameters.p_FiscalPeriod,p_FiscalYear:$parameters.p_FiscalYear) 
                                                          as   _sfi053    on            _sfi053.CompanyCode     = _JournalEntryItem.CompanyCode
                                                          //and  _sfi053.FiscalYear            = _JournalEntryItem.FiscalYear
                                                          //and  _sfi053.FiscalPeriod          = _JournalEntryItem.FiscalPeriod
                                                          and  _sfi053.PartnerCompany        = _JournalEntryItem.PartnerCompany
                                                          and  _sfi053.TransactionCurrency   = _JournalEntryItem.TransactionCurrency 
                                                          and  _sfi053.GlobalCurrency        = _JournalEntryItem.GlobalCurrency 
                                                          and  _sfi053.Item                  = _JournalEntryItem.Item    
  left outer join ZR_SFI053_1(p_FiscalPeriod : $parameters.p_FiscalPeriod,p_FiscalYear:$parameters.p_FiscalYear) 
                                                          as   _sfi053_1     on         _sfi053_1.CompanyCode     = _JournalEntryItem.CompanyCode
                                                          //and  _sfi053_1.FiscalYear            = _JournalEntryItem.FiscalYear
                                                          //and  _sfi053_1.FiscalPeriod          = _JournalEntryItem.FiscalPeriod
                                                          and  _sfi053_1.PartnerCompany        = _JournalEntryItem.PartnerCompany
                                                          and  _sfi053_1.TransactionCurrency   = _JournalEntryItem.TransactionCurrency
                                                          and  _sfi053_1.GlobalCurrency        = _JournalEntryItem.GlobalCurrency    
                                                          and  _sfi053_1.Item                  = _JournalEntryItem.Item   
    left outer join ZR_SFI052_1(p_FiscalPeriod : $parameters.p_FiscalPeriod,p_FiscalYear:$parameters.p_FiscalYear) 
                                                          as   _sfi052_1     on        _sfi052_1.CompanyCode     = _JournalEntryItem.CompanyCode
                                                         // and  _sfi052_1.FiscalYear            = _JournalEntryItem.FiscalYear
                                                          //and  _sfi052_1.FiscalPeriod          = _JournalEntryItem.FiscalPeriod
                                                          and  _sfi052_1.PartnerCompany        = _JournalEntryItem.PartnerCompany
                                                          and  _sfi052_1.TransactionCurrency   = _JournalEntryItem.TransactionCurrency
                                                          and  _sfi052_1.GlobalCurrency        = _JournalEntryItem.GlobalCurrency     
                                                          and  _sfi052_1.Item                  = _JournalEntryItem.Item                                                                                                                                      
{
  key _JournalEntryItem.CompanyCode             as CompanyCode,  
  key $parameters.p_FiscalYear                  as FiscalYear,
  key $parameters.p_FiscalPeriod                as  FiscalPeriod,
  key _JournalEntryItem.PartnerCompany          as PartnerCompany,
       @Consumption.valueHelpDefinition: [{ entity: { name: 'ZR_TFI_IC_ITEM',
                                            element: 'Item' }}]  
  key  _JournalEntryItem.Item                       as Item,  
  key _JournalEntryItem.TransactionCurrency     as TransactionCurrency, 
  key _JournalEntryItem.GlobalCurrency          as GlobalCurrency,   
     'X'                                        as Type1,
     'Y'                                        as Type2,
     _Company.CompanyCode                       as CompanyCode1,
     _CompanyCode.Company                       as PartnerCompany1,
    _CompanyCode.CompanyCodeName                as CompanyCodeName,
    _BusinessPartner.BusinessPartnerName        as BusinessPartnername,
  @Semantics: { amount : {currencyCode: 'TransactionCurrency'} } 
    _sfi052.TotalAmount                         as TotalAmount1,
  @Semantics: { amount : {currencyCode: 'TransactionCurrency'} } 
    _sfi053_1.TotalAmount                         as TotalAmount2,
  @Semantics: { amount : {currencyCode: 'TransactionCurrency'} } 
cast ( 
 (coalesce(cast(_sfi052.TotalAmount as abap.decfloat34),0) +  coalesce(cast(_sfi053_1.TotalAmount as abap.decfloat34),0) ) 
 as zzefi015 ) as Difference1,

  @Semantics: { amount : {currencyCode: 'TransactionCurrency'} } 
    _sfi053.TotalAmount                         as TotalAmount3,
  @Semantics: { amount : {currencyCode: 'TransactionCurrency'} } 
    _sfi052_1.TotalAmount                         as TotalAmount4,
  @Semantics: { amount : {currencyCode: 'TransactionCurrency'} } 
 //  ( _sfi053_1.TotalAmount  + _sfi052_1.TotalAmount )      as Difference2 ,  
 cast (  
(coalesce(cast(_sfi053.TotalAmount as abap.decfloat34),0) +  coalesce(cast(_sfi052_1.TotalAmount as abap.decfloat34),0) ) 
as zzefi015 ) as Difference2,   
   
      
   @Semantics: { amount : {currencyCode: 'TransactionCurrency'} } 
//   ( _sfi052.TotalAmount  + _sfi053.TotalAmount + _sfi053_1.TotalAmount  + _sfi052_1.TotalAmount ) as TotalDifference1,
cast ( 
 (coalesce(cast(_sfi052.TotalAmount as abap.decfloat34),0) + 
  coalesce(cast(_sfi053.TotalAmount as abap.decfloat34),0) +
  coalesce(cast(_sfi053_1.TotalAmount as abap.decfloat34),0) +
  coalesce(cast(_sfi052_1.TotalAmount as abap.decfloat34),0) )
  as zzefi015 ) as TotalDifference1,   
  
  
   @Semantics: { amount : {currencyCode: 'GlobalCurrency'} }
    _sfi052.TotalAmountGlobal                         as TotalAmountGlobal1,
  @Semantics: { amount : {currencyCode: 'GlobalCurrency'} }
    _sfi053_1.TotalAmountGlobal                         as TotalAmountGlobal2,
  @Semantics: { amount : {currencyCode: 'GlobalCurrency'} }
//   ( _sfi052.TotalAmountGlobal  + _sfi053.TotalAmountGlobal )        as Difference3,
cast (
(coalesce(cast(_sfi052.TotalAmountGlobal as abap.decfloat34),0) +  coalesce(cast(_sfi053_1.TotalAmountGlobal  as abap.decfloat34),0) ) 
as zzefi015 ) as Difference3, 


   
   @Semantics: { amount : {currencyCode: 'GlobalCurrency'} }
    _sfi053.TotalAmountGlobal                         as TotalAmountGlobal3,
  @Semantics: { amount : {currencyCode: 'GlobalCurrency'} }
    _sfi052_1.TotalAmountGlobal                         as TotalAmountGlobal4,
  @Semantics: { amount : {currencyCode: 'GlobalCurrency'} }
//   ( _sfi053_1.TotalAmountGlobal  + _sfi052_1.TotalAmountGlobal )      as Difference4  , 
cast (
(coalesce(cast(_sfi053.TotalAmountGlobal as abap.decfloat34),0) +  coalesce(cast(_sfi052_1.TotalAmountGlobal as abap.decfloat34),0) ) 
as zzefi015 ) as Difference4,
   
   @Semantics: { amount : {currencyCode: 'GlobalCurrency'} }
//   ( _sfi052.TotalAmount  + _sfi053.TotalAmount + _sfi053_1.TotalAmount  + _sfi052_1.TotalAmount ) as TotalDifference2
cast (
 (coalesce(cast(_sfi052.TotalAmountGlobal as abap.decfloat34),0) + 
  coalesce(cast(_sfi053.TotalAmountGlobal as abap.decfloat34),0) +
  coalesce(cast(_sfi053_1.TotalAmountGlobal as abap.decfloat34),0) +
  coalesce(cast(_sfi052_1.TotalAmountGlobal as abap.decfloat34),0) ) 
  as zzefi015) as TotalDifference2,
 // ReconciliationStatementsNew-Display?Item={ITEM}&FiscalYear={FiscalYear}&CompanyCode={CompanyCode}&FiscalPeriod={FiscalPeriod}&PartnerCompany={PartnerCompany}&Type='X'
 concat('ui#ReconciliationStatementsNew-Display?Item=',
 concat(_JournalEntryItem.Item,
 concat('&CompanyCode=',
 concat(_JournalEntryItem.CompanyCode,
 concat('&TransactionCurrency=',
 concat(_JournalEntryItem.TransactionCurrency,
 concat('&GlobalCurrency=',
 concat(_JournalEntryItem.GlobalCurrency,
 concat('&Type=X',
 concat('&PartnerCompany=',
 concat(_JournalEntryItem.PartnerCompany,
 concat('&p_FiscalYear=', 
 concat($parameters.p_FiscalYear,
 concat('&p_FiscalPeriod=',$parameters.p_FiscalPeriod )))))))))))))) as Url1,
 
  concat('ui#ReconciliationStatementsNew-Display?Item=',
 concat(_JournalEntryItem.Item,
 concat('&CompanyCode=',
 concat(_Company.CompanyCode,
  concat('&TransactionCurrency=',
 concat(_JournalEntryItem.TransactionCurrency,
 concat('&GlobalCurrency=',
 concat(_JournalEntryItem.GlobalCurrency,
 concat('&Type=Y',
 concat('&PartnerCompany=',
 concat(_CompanyCode.Company,
 concat('&p_FiscalYear=', 
 concat($parameters.p_FiscalYear,
 concat('&p_FiscalPeriod=',$parameters.p_FiscalPeriod )))))))))))))) as Url2,
 
  concat('ui#ReconciliationStatementsNew-Display?Item=',
 concat(_JournalEntryItem.Item,
 concat('&CompanyCode=',
 concat(_JournalEntryItem.CompanyCode,
  concat('&TransactionCurrency=',
 concat(_JournalEntryItem.TransactionCurrency,
 concat('&GlobalCurrency=',
 concat(_JournalEntryItem.GlobalCurrency,
 concat('&Type=Y',
 concat('&PartnerCompany=',
 concat(_JournalEntryItem.PartnerCompany,
 concat('&p_FiscalYear=', 
 concat($parameters.p_FiscalYear,
 concat('&p_FiscalPeriod=',$parameters.p_FiscalPeriod )))))))))))))) as Url3,
 
  concat('ui#ReconciliationStatementsNew-Display?Item=',
 concat(_JournalEntryItem.Item,
 concat('&CompanyCode=',
 concat(_Company.CompanyCode,
  concat('&TransactionCurrency=',
 concat(_JournalEntryItem.TransactionCurrency,
 concat('&GlobalCurrency=',
 concat(_JournalEntryItem.GlobalCurrency,
 concat('&Type=X',
 concat('&PartnerCompany=',
 concat(_CompanyCode.Company,
 concat('&p_FiscalYear=', 
 concat($parameters.p_FiscalYear,
 concat('&p_FiscalPeriod=',$parameters.p_FiscalPeriod )))))))))))))) as Url4
 
} 
